//  MXAudioPlayerFadeOperation.h
//
//  Created by Andrew Mackenzie-Ross on 30/11/10.
//  mackross.net
//

#import <Foundation/Foundation.h>

@class AVAudioPlayer;
@interface MXAudioPlayerFadeOperation : NSOperation {
  AVAudioPlayer *_audioPlayer;
  NSTimeInterval _fadeDuration;
  NSTimeInterval _delay;
  float _finishVolume;
  BOOL _pauseAfterFade;
  BOOL _stopAfterFade;
  BOOL _playBeforeFade;
}

// The AVAudioPlayer that the volume fade will be applied to.
// Retained until the fade is completed.
// Must be set with init method.
@property (nonatomic, strong, readonly) AVAudioPlayer *audioPlayer;

// The duration of the volume fade.
// Default value is 1.0
@property (nonatomic, assign) NSTimeInterval fadeDuration;

// The delay before the volume fade begins.
// Default value is 0.0
@property (nonatomic, assign) NSTimeInterval delay;

// The volume that will be faded to.
// Default value is 0.0
@property (nonatomic, assign) float finishVolume;

// If YES, audio player will be sent a pause message when the fade has completed.
// Default value is NO, however, if finishVolume is 0.0, default is YES
@property (nonatomic, assign) BOOL pauseAfterFade;

// If YES, when the fade has completed the audio player will be sent a stop message.
// Default value is NO.
@property (nonatomic, assign) BOOL stopAfterFade;

// If YES, audio player will be sent a play message after the delay.
// Default value is YES.
@property (nonatomic, assign) BOOL playBeforeFade;

// Init Methods
- (id)initFadeWithAudioPlayer:(AVAudioPlayer*)player toVolume:(float)volume overDuration:(NSTimeInterval)duration withDelay:(NSTimeInterval)timeDelay;
- (id)initFadeWithAudioPlayer:(AVAudioPlayer*)player toVolume:(float)volume overDuration:(NSTimeInterval)duration;
- (id)initFadeWithAudioPlayer:(AVAudioPlayer*)player toVolume:(float)volume;
- (id)initFadeWithAudioPlayer:(AVAudioPlayer*)player;

@end
