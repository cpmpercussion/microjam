#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AudioHelpers.h"
#import "PdAudioController.h"
#import "PdAudioUnit.h"
#import "PdBase.h"
#import "PdDispatcher.h"
#import "PdFile.h"
#import "PdMidiDispatcher.h"

FOUNDATION_EXPORT double libpdVersionNumber;
FOUNDATION_EXPORT const unsigned char libpdVersionString[];

