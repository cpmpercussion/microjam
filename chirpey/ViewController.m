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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startAudioEngine];
    // Do any additional setup after loading the view, typically from a nib.
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

@end
