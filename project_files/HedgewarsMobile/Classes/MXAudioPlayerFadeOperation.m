//  MXAudioPlayerFadeOperation.m
//
//  Created by Andrew Mackenzie-Ross on 30/11/10.
//  mackross.net.
//

#import "MXAudioPlayerFadeOperation.h"
#import <AVFoundation/AVFoundation.h>

#define SKVolumeChangesPerSecond 15

@interface MXAudioPlayerFadeOperation ()
@property (nonatomic, retain, readwrite) AVAudioPlayer *audioPlayer;
- (void)beginFadeOperation;
- (void)finishFadeOperation;
@end

@implementation MXAudioPlayerFadeOperation
#pragma mark -
#pragma mark Properties
@synthesize audioPlayer = _audioPlayer;
@synthesize fadeDuration = _fadeDuration;
@synthesize finishVolume = _finishVolume;
@synthesize playBeforeFade = _playBeforeFade;
@synthesize pauseAfterFade = _pauseAfterFade;
@synthesize stopAfterFade = _stopAfterFade;
@synthesize delay = _delay;

#pragma mark -
#pragma mark Accessors
- (AVAudioPlayer *)audioPlayer {
  AVAudioPlayer *result;
  @synchronized(self) {
    result = [_audioPlayer retain];
  }
  return [result autorelease];
}

- (void)setAudioPlayer:(AVAudioPlayer *)anAudioPlayer {
  @synchronized(self) {
    if (_audioPlayer != anAudioPlayer) {
      [_audioPlayer release];
      _audioPlayer = [anAudioPlayer retain];
    }
  }
}

#pragma mark -
#pragma mark NSOperation
-(id) initFadeWithAudioPlayer:(AVAudioPlayer*)player toVolume:(float)volume overDuration:(NSTimeInterval)duration withDelay:(NSTimeInterval)timeDelay {
  if ((self = [super init])) {
    self.audioPlayer = player;
    [player prepareToPlay];
    _fadeDuration = duration;
    _finishVolume = volume;
    _playBeforeFade = YES;
    _stopAfterFade = NO;
    _pauseAfterFade = (volume == 0.0) ? YES : NO;
    _delay = timeDelay;
  }
  return self;
}

- (id)initFadeWithAudioPlayer:(AVAudioPlayer*)player toVolume:(float)volume overDuration:(NSTimeInterval)duration {
  return [self initFadeWithAudioPlayer:player toVolume:volume overDuration:duration withDelay:0.0];
}

- (id)initFadeWithAudioPlayer:(AVAudioPlayer*)player toVolume:(float)volume {
  return [self initFadeWithAudioPlayer:player toVolume:volume overDuration:1.0];
}

- (id)initFadeWithAudioPlayer:(AVAudioPlayer*)player {
  return [self initFadeWithAudioPlayer:player toVolume:0.0];
}

- (id) init {
  ALog(@"Failed to init class (%@) with AVAudioPlayer instance, use initFadeWithAudioPlayer:",[self class]);
  return nil;
}

- (void)main {
  @autoreleasepool {

  [NSThread sleepForTimeInterval:_delay];
  if ([self.audioPlayer isKindOfClass:[AVAudioPlayer class]]) {
    [self beginFadeOperation];
  }
  else {
    ALog(@"AudioPlayerFadeOperation began with invalid AVAudioPlayer");
  }

  }
}

- (void)beginFadeOperation {
  if (![self.audioPlayer isPlaying] && _playBeforeFade) [self.audioPlayer play];

  if (_fadeDuration != 0.0) {

    NSTimeInterval sleepInterval = (1.0 / SKVolumeChangesPerSecond);
    NSTimeInterval startTime = [[NSDate date] timeIntervalSinceReferenceDate];
    NSTimeInterval now = startTime;

    float startVolume = [self.audioPlayer volume];

    while (now < (startTime + _fadeDuration)) {
      float ratioOfFadeCompleted = (now - startTime)/_fadeDuration;
      float volume = (_finishVolume * ratioOfFadeCompleted) + (startVolume * (1-ratioOfFadeCompleted));
      [self.audioPlayer setVolume:volume];
      [NSThread sleepForTimeInterval:sleepInterval];
      now = [[NSDate date] timeIntervalSinceReferenceDate];
    }

    [self.audioPlayer setVolume:_finishVolume];
    [self finishFadeOperation];
  }
  else {
    [self.audioPlayer setVolume:_finishVolume];
    [self finishFadeOperation];
  }
}

- (void)finishFadeOperation {
  if ([self.audioPlayer isPlaying] && _pauseAfterFade) [self.audioPlayer pause];
  if ([self.audioPlayer isPlaying] && _stopAfterFade) [self.audioPlayer stop];
}

- (void)dealloc {
  releaseAndNil(_audioPlayer);
  [super dealloc];
}

@end

