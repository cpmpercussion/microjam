//
//  ViewController.m
//  chirpey
//
//  Created by Charles Martin on 7/10/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet ChirpView *chirpeySquare;
@property (weak, nonatomic) IBOutlet UIProgressView *recordingProgress;
@property (nonatomic) double progress;
@property (strong, nonatomic) NSTimer *progressTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startAudioEngine];
    self.recordingProgress.progress = 0.0f;
    // Do any additional setup after loading the view, typically from a nib.
#if TARGET_IPHONE_SIMULATOR
    // where are you?
    NSLog(@"Documents Directory: %@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);
#endif

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#define SOUND_OUTPUT_CHANNELS 2
#define SAMPLE_RATE 44100
#define TICKS_PER_BUFFER 4
#define PATCH_NAME @"chirp.pd"

- (void) startAudioEngine {
    NSLog(@"VC: Starting Audio Engine");
    self.audioController = [[PdAudioController alloc] init];
    [self.audioController configurePlaybackWithSampleRate:SAMPLE_RATE numberChannels:SOUND_OUTPUT_CHANNELS inputEnabled:NO mixingEnabled:YES];
    [self.audioController configureTicksPerBuffer:TICKS_PER_BUFFER];
    //    [self openPdPatch];
    [PdBase setDelegate:self];
    [PdBase subscribe:@"toGUI"];
    [PdBase openFile:PATCH_NAME path:[[NSBundle mainBundle] bundlePath]];
    [self.audioController setActive:YES];
    [self.audioController print];
    NSLog(@"VC: Ticks Per Buffer: %d",self.audioController.ticksPerBuffer);
}

#pragma mark - Pd Send/Receive Methods
-(void) receivePrint:(NSString *)message {
    NSLog(@"Pd: %@",message);
}

#pragma mark - Progress Bar

- (void) startTimer
{
    NSLog(@"Starting the timer");
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateProgressView) userInfo:nil repeats:YES];
    self.chirpeySquare.recording = YES;
    
}

-(void) stopTimer
{
    [self.progressTimer invalidate];
    self.progress = 0.0f;
    self.recordingProgress.progress = 0.0f;
    NSLog(@"Timer Stopped");
    NSMutableOrderedSet *record = [self.chirpeySquare reset];
    NSString *recordingString = [self createCSVFromOrderedSet:record];
    [self writeCSVToFile:recordingString];
}

- (void) updateProgressView
{
    self.progress += 0.01f;
    self.recordingProgress.progress = self.progress / 5.0;
    if (self.progress >= 5.0) [self stopTimer];
}


#pragma mark - Touch Methods
- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  // start timer if not recording
    UITouch *aTouch = [touches anyObject];
    CGPoint p = [aTouch locationInView:self.chirpeySquare];
    if (CGRectContainsPoint(self.chirpeySquare.bounds, p))
    {
        if (!self.chirpeySquare.recording) {
            [self startTimer];
        }
    }
}

#pragma mark - data processing methods
- (NSString *) createCSVFromOrderedSet:(NSMutableOrderedSet *) set
{
    NSString *output = @"time,x,y,z,moving\n";
    for (NSArray *item in set) {
        NSString *line = [NSString stringWithFormat:@"%f, %f, %f, %f,%d\n", [(NSNumber *) item[0] floatValue], [(NSNumber *) item[1] floatValue], [(NSNumber *) item[2] floatValue], [(NSNumber *) item[3] floatValue],[(NSNumber *) item[4] intValue]];
        output = [output stringByAppendingString:line];
    }
    //output = [output stringByAppendingString:@" \n "];
    return output;
}

- (void) writeCSVToFile:(NSString *)csvString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-DD-HH-mm-SS"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"chirprec-%@", dateString];
    NSString *filePath =  [documentsDirectory stringByAppendingPathComponent:fileName];

    NSError *err = nil;
    [csvString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    NSLog(@"Wrote the file?");
}

@end
