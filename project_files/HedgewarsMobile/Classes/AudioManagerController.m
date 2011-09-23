/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 13/03/2011.
 */


#import "AudioManagerController.h"
#import "AVFoundation/AVAudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>


static AVAudioPlayer *backgroundMusic = nil;
static SystemSoundID clickSound = -1;
static SystemSoundID backSound = -1;
static SystemSoundID selSound = -1;

@implementation AudioManagerController

#pragma mark -
#pragma mark background music control
+(void) loadBackgroundMusic {
    NSString *musicString = [[NSBundle mainBundle] pathForResource:@"hwclassic" ofType:@"mp3"];
    backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:musicString] error:nil];

    backgroundMusic.delegate = nil;
    backgroundMusic.volume = 0.4f;
    backgroundMusic.numberOfLoops = -1;
    [backgroundMusic prepareToPlay];
}

+(void) playBackgroundMusic {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"music"] boolValue] == NO)
        return;

    if (backgroundMusic == nil)
        [AudioManagerController loadBackgroundMusic];

    [backgroundMusic play];
}

+(void) pauseBackgroundMusic {
    [backgroundMusic pause];
}

+(void) stopBackgroundMusic {
    [backgroundMusic stop];
}

#pragma mark -
#pragma mark sound effects control
+(SystemSoundID) loadSound:(NSString *)snd {
    // get the filename of the sound file:
    NSString *path = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],snd];

    // declare a system sound id and get a URL for the sound file
    SystemSoundID soundID;
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];

    // use audio sevices to create and play the sound
    AudioServicesCreateSystemSoundID((CFURLRef)filePath, &soundID);
    return soundID;
}

+(void) playClickSound {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"sound"] boolValue] == NO)
        return;
    
    if (clickSound == -1)
        clickSound = [AudioManagerController loadSound:@"clickSound.wav"];
    
    AudioServicesPlaySystemSound(clickSound);
}

+(void) playBackSound {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"sound"] boolValue] == NO)
        return;
    
    if (backSound == -1)
        backSound = [AudioManagerController loadSound:@"backSound.wav"];
    
    AudioServicesPlaySystemSound(backSound);
}

+(void) playSelectSound {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"sound"] boolValue] == NO)
        return;
    
    if (selSound == -1)
        selSound = [AudioManagerController loadSound:@"selSound.wav"];
    
    AudioServicesPlaySystemSound(selSound);
}

#pragma mark -
#pragma mark memory management
+(void) didReceiveMemoryWarning {
    [backgroundMusic stop];
    backgroundMusic = nil;
    clickSound = -1;
    backSound = -1;
}

+(void) dealloc {
    releaseAndNil(backgroundMusic);
    AudioServicesDisposeSystemSoundID(clickSound), clickSound = -1;
    AudioServicesDisposeSystemSoundID(backSound), backSound = -1;
    AudioServicesDisposeSystemSoundID(selSound), selSound = -1;
    [super dealloc];
}

@end
