/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import "AudioManagerController.h"
#import "AVFoundation/AVAudioPlayer.h"
#import "MXAudioPlayerFadeOperation.h"


#define DEFAULT_VOLUME    0.45f
#define FADEOUT_DURATION  3.0f
#define FADEIN_DURATION   2.0f

static AudioManagerController *mainInstance;

@implementation AudioManagerController
@synthesize backgroundMusic, clickSound, backSound, selSound, audioFaderQueue;

+(id) mainManager {
    if (mainInstance == nil)
        mainInstance = [[self alloc] init];
    return mainInstance;
}

-(id) init {
    if ((self = [super init])) {
        self.backgroundMusic = nil;
        self.clickSound = -1;
        self.backSound = -1;
        self.selSound = -1;

        self.audioFaderQueue = nil;
    }
    return self;
}

-(void) dealloc {
    [self unloadSounds];
    releaseAndNil(backgroundMusic);
    releaseAndNil(audioFaderQueue);
    mainInstance = nil;
    [super dealloc];
}

-(void) didReceiveMemoryWarning {
    if (self.backgroundMusic.playing == NO)
        self.backgroundMusic = nil;
    if ([self.audioFaderQueue operationCount] == 0)
        self.audioFaderQueue = nil;

    [self unloadSounds];
    MSG_MEMCLEAN();
}

#pragma mark -
#pragma mark background music control
-(void) playBackgroundMusic {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"music"] boolValue] == NO)
        return;

    if (self.backgroundMusic == nil) {
        NSString *musicString = [[NSBundle mainBundle] pathForResource:@"hwclassic" ofType:@"mp3"];
        self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:musicString] error:nil];
        self.backgroundMusic.delegate = nil;
        self.backgroundMusic.numberOfLoops = -1;
    }

    self.backgroundMusic.volume = DEFAULT_VOLUME;
    [self.backgroundMusic play];
}

-(void) pauseBackgroundMusic {
    [self.backgroundMusic pause];
}

-(void) stopBackgroundMusic {
    [self.backgroundMusic stop];
}

-(void) fadeOutBackgroundMusic {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"music"] boolValue] == NO)
        return;

    if (self.audioFaderQueue == nil)
        self.audioFaderQueue = [[NSOperationQueue alloc] init];

    MXAudioPlayerFadeOperation *fadeOut = [[MXAudioPlayerFadeOperation alloc] initFadeWithAudioPlayer:self.backgroundMusic
                                                                                             toVolume:0.0
                                                                                         overDuration:FADEOUT_DURATION];
    [self.audioFaderQueue addOperation:fadeOut];
    [fadeOut release];
}

-(void) fadeInBackgroundMusic {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"music"] boolValue] == NO)
        return;

    if (self.audioFaderQueue == nil)
        self.audioFaderQueue = [[NSOperationQueue alloc] init];

    [self playBackgroundMusic];
    MXAudioPlayerFadeOperation *fadeIn = [[MXAudioPlayerFadeOperation alloc] initFadeWithAudioPlayer:self.backgroundMusic
                                                                                            toVolume:DEFAULT_VOLUME
                                                                                        overDuration:FADEIN_DURATION];
    [audioFaderQueue addOperation:fadeIn];
    [fadeIn release];
}

#pragma mark -
#pragma mark sound effects control
-(SystemSoundID) loadSound:(NSString *)snd {
    SystemSoundID soundID;

    // get the filename of the sound file in a NSURL format
    NSString *path = [[NSBundle mainBundle] pathForResource:snd ofType:@"caf"];
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];

    // use audio sevices to create and play the sound
    AudioServicesCreateSystemSoundID((CFURLRef)filePath, &soundID);
    return soundID;
}

-(void) unloadSounds {
    AudioServicesDisposeSystemSoundID(clickSound), clickSound = -1;
    AudioServicesDisposeSystemSoundID(backSound), backSound = -1;
    AudioServicesDisposeSystemSoundID(selSound), selSound = -1;
}

-(void) playClickSound {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"sound"] boolValue] == NO)
        return;

    if (self.clickSound == -1)
        self.clickSound = [self loadSound:@"clickSound"];

    AudioServicesPlaySystemSound(self.clickSound);
}

-(void) playBackSound {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"sound"] boolValue] == NO)
        return;

    if (self.backSound == -1)
        self.backSound = [self loadSound:@"backSound"];

    AudioServicesPlaySystemSound(self.backSound);
}

-(void) playSelectSound {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"sound"] boolValue] == NO)
        return;

    if (self.selSound == -1)
        self.selSound = [self loadSound:@"selSound"];

    AudioServicesPlaySystemSound(self.selSound);
}

@end
