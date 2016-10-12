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
    }
    return self;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.swiped = false;
    self.lastPoint = [(UITouch *) [touches anyObject] locationInView:self];
    for (UITouch * touch in [touches objectEnumerator]) {
        CGPoint point = [touch locationInView:self];
        NSLog(@"Touch Down at: %f, %f", point.x,point.y);
        NSNumber *x = [NSNumber numberWithFloat:(float) point.x / 300.0];
        NSNumber *y = [NSNumber numberWithFloat:(float) point.y / 300.0];
        NSNumber *z = [NSNumber numberWithFloat:0.0];
        [PdBase sendList:@[@"/x",x,@"/y",y,@"/z",z] toReceiver:@"input"];
    }
    
}

-(void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.swiped = true;
    CGPoint currentPoint = [(UITouch *) [touches anyObject] locationInView:self];
    [self drawLineFrom:self.lastPoint to:currentPoint];
    
    for (UITouch * touch in [touches objectEnumerator]) {
        CGPoint point = [touch locationInView:self];
        NSLog(@"Touch Down at: %f, %f", point.x,point.y);
        NSNumber *x = [NSNumber numberWithFloat:(float) point.x / 300.0];
        NSNumber *y = [NSNumber numberWithFloat:(float) point.y / 300.0];
        NSNumber *z = @0.0;
        [PdBase sendList:@[@"/x",x,@"/y",y,@"/z",z] toReceiver:@"input"];
    }
    
    self.lastPoint = currentPoint;
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}


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
