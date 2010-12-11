/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * File created on 30/10/2010.
 */


#import "ObjcExports.h"
#import "AmmoMenuViewController.h"
#import "AudioToolbox/AudioToolbox.h"

#pragma mark -
#pragma mark internal variables
// actual game started (controls should be enabled)
BOOL gameRunning;
// black screen present
BOOL savedGame;
// cache the grenade time
NSInteger grenadeTime;
// the reference to the newMenu instance
AmmoMenuViewController *amvc_instance;
// the audiosession must be initialized before using properties
BOOL gAudioSessionInited = NO;

#pragma mark -
#pragma mark functions called like oop
void objcExportsInit() {
    gameRunning = NO;
    savedGame = NO;
    grenadeTime = 2;
}

BOOL inline isGameRunning() {
    return gameRunning;
}

void inline setGameRunning(BOOL value) {
    gameRunning = value;
}

NSInteger cachedGrenadeTime() {
    return grenadeTime;
}

void inline setGrenadeTime(NSInteger value) {
    grenadeTime = value;
}

void inline setAmmoMenuInstance(AmmoMenuViewController *instance) {
    amvc_instance = instance;
}

#pragma mark -
#pragma mark functions called by pascal code
void startSpinning() {
    gameRunning = NO;
    UIWindow *theWindow = [[UIApplication sharedApplication] keyWindow];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.tag = ACTIVITYINDICATOR_TAG;
    int offset;
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft)
        offset = -120;
    else
        offset = 120;
    if (IS_DUALHEAD())
        indicator.center = CGPointMake(theWindow.frame.size.width/2, theWindow.frame.size.height/2 + offset);
    else
        indicator.center = CGPointMake(theWindow.frame.size.width/2 + offset, theWindow.frame.size.height/2);
    indicator.hidesWhenStopped = YES;
    [indicator startAnimating];
    [theWindow addSubview:indicator];
    [indicator release];
}

void stopSpinning() {
    UIWindow *theWindow = [[UIApplication sharedApplication] keyWindow];
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[theWindow viewWithTag:ACTIVITYINDICATOR_TAG];
    [indicator stopAnimating];
    HW_zoomSet(1.7);
    if (savedGame == NO)
        gameRunning = YES;
}

void clearView() {
    // don't use any engine calls here as this function is called every time the ammomenu is opened
    UIWindow *theWindow = (IS_DUALHEAD()) ? [SDLUIKitDelegate sharedAppDelegate].uiwindow : [[UIApplication sharedApplication] keyWindow];
    UIButton *theButton = (UIButton *)[theWindow viewWithTag:CONFIRMATION_TAG];
    UISegmentedControl *theSegment = (UISegmentedControl *)[theWindow viewWithTag:GRENADE_TAG];

    [UIView beginAnimations:@"remove button" context:NULL];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    theButton.alpha = 0;
    theSegment.alpha = 0;
    [UIView commitAnimations];

    if (theButton)
        [theWindow performSelector:@selector(removeFromSuperview) withObject:theButton afterDelay:ANIMATION_DURATION];
    if (theSegment)
        [theWindow performSelector:@selector(removeFromSuperview) withObject:theSegment afterDelay:ANIMATION_DURATION];

    grenadeTime = 2;
}

void replayBegan() {
    UIWindow *theWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *blackView = [[UIView alloc] initWithFrame:theWindow.frame];
    blackView.backgroundColor = [UIColor blackColor];
    blackView.alpha = 0.6;
    blackView.tag = REPLAYBLACKVIEW_TAG;
    blackView.exclusiveTouch = NO;
    blackView.multipleTouchEnabled = NO;
    blackView.userInteractionEnabled = NO;

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = theWindow.center;
    [indicator startAnimating];
    [blackView addSubview:indicator];
    [indicator release];
    [theWindow addSubview:blackView];
    [blackView release];

    savedGame = YES;
    stopSpinning();
}

void replayFinished() {
    UIWindow *theWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *blackView = (UIView *)[theWindow viewWithTag:REPLAYBLACKVIEW_TAG];

    [UIView beginAnimations:@"removing black" context:NULL];
    [UIView setAnimationDuration:1];
    blackView.alpha = 0;
    [UIView commitAnimations];
    [theWindow performSelector:@selector(removeFromSuperview) withObject:blackView afterDelay:1];

    gameRunning = YES;
    savedGame = NO;
}

void updateVisualsNewTurn(void) {
    DLog(@"updating visuals");
    [amvc_instance updateAmmoVisuals];
}

/*
// http://stackoverflow.com/questions/287543/how-to-programatically-sense-the-iphone-mute-switch
BOOL isAppleDeviceMuted(void) {
    if (!gAudioSessionInited) {
        AudioSessionInterruptionListener inInterruptionListener = NULL;
        OSStatus error;
        if ((error = AudioSessionInitialize(NULL, NULL, inInterruptionListener, NULL)))
            DLog(@"*** Error *** error in AudioSessionInitialize: %d", error);
        else
            gAudioSessionInited = YES;
    }
    UInt32 propertySize = sizeof(CFStringRef);
    BOOL muteResult = NO;

    // this checks if there is volume
    Float32 volume;
    OSStatus n = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume, &propertySize, &volume);
    if (n != 0)
        DLog( @"AudioSessionGetProperty 'volume': %d", n );
    BOOL volumeResult = (volume == 0.0f);
    
    // this checks if the device is muted
    CFStringRef state;
    n = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
    if (n != 0)
        DLog( @"AudioSessionGetProperty 'audioRoute': %d", n );
    else {
        NSString *result = (NSString *)state;
        muteResult = ([result length] == 0);
        releaseAndNil(result);
    }
    return volumeResult || muteResult;
}
*/
