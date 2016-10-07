//
//  ViewController.h
//  chirpey
//
//  Created by Charles Martin on 7/10/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PdAudioController.h"
#import "PdBase.h"
#import "PdFile.h"

@interface ViewController : UIViewController <PdReceiverDelegate>
@property (strong, nonatomic) PdAudioController *audioController;
@property (strong, nonatomic) PdFile *openFile;
@end


