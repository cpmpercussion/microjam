//
//  chirpView.h
//  chirpey
//
//  Created by Charles Martin on 7/10/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChirpView : UIImageView
@property (strong, nonatomic) CALayer *fingerSubLayer;
@property (nonatomic) bool recording;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSMutableOrderedSet *reset;
- (void) playBackRecording: (NSMutableOrderedSet *) record;
@end

