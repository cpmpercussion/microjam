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
@end

@implementation ChirpView

- (id) initWithCoder:(NSCoder *)aDecoder
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
    [self makeSoundAtPoint:self.lastPoint];
    [self recordTouchAtPoint:self.lastPoint thatWasMoving:NO];
}

-(void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.swiped = true;
    CGPoint currentPoint = [(UITouch *) [touches anyObject] locationInView:self];
    [self drawLineFrom:self.lastPoint to:currentPoint];
    self.lastPoint = currentPoint;
    [self makeSoundAtPoint:currentPoint];
    [self recordTouchAtPoint:currentPoint thatWasMoving:YES];
}

-(void) makeSoundAtPoint: (CGPoint) point
{
    NSNumber *x = [NSNumber numberWithFloat:(float) point.x / 300.0];
    NSNumber *y = [NSNumber numberWithFloat:(float) point.y / 300.0];
    NSNumber *z = @0.0;
    [PdBase sendList:@[@"/x",x,@"/y",y,@"/z",z] toReceiver:@"input"];
}

-(void) recordTouchAtPoint: (CGPoint)point thatWasMoving: (bool)moving
{
    NSNumber *time = [NSNumber numberWithDouble:(-1.0 * [self.startTime timeIntervalSinceNow])];
    NSNumber *x = [NSNumber numberWithFloat:(float) point.x / 300.0];
    NSNumber *y = [NSNumber numberWithFloat:(float) point.y / 300.0];
    NSNumber *z = @0.0;
    NSNumber *movingObj = [NSNumber numberWithBool:moving];
    NSArray* touchPoint = @[time, x, y, z, movingObj];
    [self.recordData addObject:touchPoint];
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}


- (void) drawLineFrom:(CGPoint) fromPoint to:(CGPoint) toPoint
{
    UIGraphicsBeginImageContext(self.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    
    CGContextMoveToPoint(context, fromPoint.x, fromPoint.y);
    CGContextAddLineToPoint(context, toPoint.x, toPoint.y);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 10.0);
    CGContextSetRGBStrokeColor(context, 255, 0, 0, 1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextStrokePath(context);
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
