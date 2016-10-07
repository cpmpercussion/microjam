//
//  chirpView.m
//  chirpey
//
//  Created by Charles Martin on 7/10/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

#import "ChirpView.h"
#import "PdBase.h"
@implementation ChirpView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch * touch in [touches objectEnumerator]) {
        CGPoint point = [touch locationInView:self];
        NSLog(@"Touch Down at: %f, %f", point.x,point.y);
        NSNumber *x = [NSNumber numberWithFloat:(float) point.x / 300.0];
        NSNumber *y = [NSNumber numberWithFloat:(float) point.y / 300.0];
        NSNumber *z = @0.0;
        [PdBase sendList:@[@"/x",x,@"/y",y,@"/z",z] toReceiver:@"input"];
    }
}

-(void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch * touch in [touches objectEnumerator]) {
        CGPoint point = [touch locationInView:self];
        NSLog(@"Touch Down at: %f, %f", point.x,point.y);
        NSNumber *x = [NSNumber numberWithFloat:(float) point.x / 300.0];
        NSNumber *y = [NSNumber numberWithFloat:(float) point.y / 300.0];
        NSNumber *z = @0.0;
        [PdBase sendList:@[@"/x",x,@"/y",y,@"/z",z] toReceiver:@"input"];
    }
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

@end
