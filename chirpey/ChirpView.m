//
//  chirpView.m
//  chirpey
//
//  Created by Charles Martin on 7/10/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

#import "ChirpView.h"
#import "PdBase.h"

@interface ChirpView()
@property (nonatomic) CGPoint lastPoint;
@property (nonatomic) bool swiped;
@property (nonatomic) bool started;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSMutableOrderedSet *recordData;
@property (nonatomic) CGColorRef recordingColour;
@property (nonatomic) CGColorRef playbackColour;
@end

@implementation ChirpView

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // init code
        self.fingerSubLayer = [[CALayer alloc] init];
        [self.layer addSublayer:self.fingerSubLayer];
        self.multipleTouchEnabled = YES;
        self.lastPoint = CGPointZero;
        self.swiped = false;
        self.recordData = [[NSMutableOrderedSet alloc] init];
        CGFloat red[4] = {1.0,0.0,0.0,1.0};
        CGFloat green[4] = {0.0,1.0,0.0,1.0};
        self.recordingColour = CGColorCreate(CGColorSpaceCreateDeviceRGB(), red);
        self.playbackColour = CGColorCreate(CGColorSpaceCreateDeviceRGB(), green);
    }
    return self;
}

- (NSMutableOrderedSet *) reset
{
    self.recording = NO;
    self.started = NO;
    self.lastPoint = CGPointZero;
    self.swiped = false;
    // spool out the recording data
    NSMutableOrderedSet *output = self.recordData;
    self.recordData = [[NSMutableOrderedSet alloc] init];
    self.image = [[UIImage alloc] init];
    return output;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.superview touchesBegan:touches withEvent:event];
    if (!self.started) {
        self.startTime = [NSDate date];
        self.started = YES;
    }
    self.swiped = false;
    self.lastPoint = [(UITouch *) [touches anyObject] locationInView:self];
    [self drawDotAt:self.lastPoint withColour:self.recordingColour];
    [self makeSoundAtPoint:self.lastPoint];
    [self recordTouchAtPoint:self.lastPoint thatWasMoving:NO];
}

-(void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.swiped = true;
    CGPoint currentPoint = [(UITouch *) [touches anyObject] locationInView:self];
    [self drawLineFrom:self.lastPoint to:currentPoint withColour:self.recordingColour];
    self.lastPoint = currentPoint;
    [self makeSoundAtPoint:currentPoint];
    [self recordTouchAtPoint:currentPoint thatWasMoving:YES];
}

-(void) makeSoundAtPoint: (CGPoint) point
{
    NSNumber *x = @(point.x / 300.0);
    NSNumber *y = @(point.y / 300.0);
    NSNumber *z = @0.0;
    [PdBase sendList:@[@"/x",x,@"/y",y,@"/z",z] toReceiver:@"input"];
}

-(void) recordTouchAtPoint: (CGPoint)point thatWasMoving: (bool)moving
{
    NSNumber *time = @(-1.0 * (self.startTime).timeIntervalSinceNow);
    NSNumber *x = [NSNumber numberWithFloat:(float) point.x / 300.0];
    NSNumber *y = [NSNumber numberWithFloat:(float) point.y / 300.0];
    NSNumber *z = @0.0;
    NSNumber *movingObj = @(moving);
    NSArray* touchPoint = @[time, x, y, z, movingObj];
    [self.recordData addObject:touchPoint];
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}


- (void) drawDotAt:(CGPoint) point withColour:(CGColorRef) color
{
    UIGraphicsBeginImageContext(self.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    CGContextSetFillColorWithColor(context,color);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextFillEllipseInRect(context, CGRectMake(point.x - 5, point.y - 5, 10, 10));
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void) drawLineFrom:(CGPoint) fromPoint to:(CGPoint) toPoint withColour:(CGColorRef) color
{
    UIGraphicsBeginImageContext(self.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    
    CGContextMoveToPoint(context, fromPoint.x, fromPoint.y);
    CGContextAddLineToPoint(context, toPoint.x, toPoint.y);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 10.0);
    CGContextSetFillColorWithColor(context,color);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextStrokePath(context);
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}


-(void) playBackBegan:(CGPoint) point
{
    self.swiped = false;
    self.lastPoint = point;
    [self drawDotAt:point withColour:self.playbackColour];
    [self makeSoundAtPoint:point];
}

-(void) playBackMoved:(CGPoint) point
{
    self.swiped = true;
    [self drawLineFrom:self.lastPoint to:point withColour:self.recordingColour];
    self.lastPoint = point;
    [self makeSoundAtPoint:point];
}

- (void) playBackRecording: (NSMutableOrderedSet *) record
{
    for (NSArray *touch in record) {
        double time = ((NSNumber *) touch[0]).doubleValue;
        [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(processTimedTouch:) userInfo:touch repeats:NO];
    }
}

- (void) processTimedTouch:(NSTimer *)timer
{
    NSArray *touch = (NSArray *) timer.userInfo;
    float x = 300.0 * ((NSNumber *) touch[1]).floatValue;
    float y = 300.0 * ((NSNumber *) touch[2]).floatValue;
    //float z = [(NSNumber *) touch[3] floatValue];
    CGPoint point = CGPointMake((CGFloat) x, (CGFloat) y);
    bool moved = ((NSNumber *) touch[4]).boolValue;
    if (moved) {
        [self playBackMoved:point];
    } else {
        [self playBackBegan:point];
    }
}

@end
