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
 * File created on 30/10/2010.
 */


#import "ObjcExports.h"
#import "OverlayViewController.h"
#import "AmmoMenuViewController.h"

#pragma mark -
#pragma mark internal variables
// actual game started (controls should be enabled)
BOOL gameRunning;
// black screen present
BOOL savedGame;
// cache the grenade time
NSInteger grenadeTime;
// the reference to the newMenu instance
OverlayViewController *overlay_instance;
// the audiosession must be initialized before using properties
BOOL gAudioSessionInited = NO;

#pragma mark -
#pragma mark functions called like oop
void objcExportsInit(OverlayViewController* instance) {
    overlay_instance = instance;
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

#pragma mark -
#pragma mark functions called by pascal code
void startSpinningProgress() {
    gameRunning = NO;
    overlay_instance.lowerIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

    CGPoint center = overlay_instance.view.center;
    overlay_instance.lowerIndicator.center = (IS_DUALHEAD() ? CGPointMake(center.y, center.x)
                                              : CGPointMake(center.y, center.x * 5/3));

    [overlay_instance.lowerIndicator startAnimating];
    [overlay_instance.view addSubview:overlay_instance.lowerIndicator];
    [overlay_instance.lowerIndicator release];
}

void stopSpinningProgress() {
    [overlay_instance.lowerIndicator stopAnimating];
    [overlay_instance.lowerIndicator removeFromSuperview];
    HW_zoomSet(1.7);
    if (savedGame == NO)
        gameRunning = YES;
}

void clearView() {
    // don't use any engine calls here as this function is called every time the ammomenu is opened
    UIWindow *theWindow = (IS_DUALHEAD()) ? [HedgewarsAppDelegate sharedAppDelegate].uiwindow : [[UIApplication sharedApplication] keyWindow];
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

void saveBeganSynching() {
    overlay_instance.view.backgroundColor = [UIColor blackColor];
    overlay_instance.view.alpha = 0.75;
    overlay_instance.view.userInteractionEnabled = NO;

    overlay_instance.savesIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

    CGPoint center = overlay_instance.view.center;
    overlay_instance.savesIndicator.center = CGPointMake(center.y, center.x);
    overlay_instance.savesIndicator.hidesWhenStopped = YES;

    [overlay_instance.savesIndicator startAnimating];
    [overlay_instance.view addSubview:overlay_instance.savesIndicator];
    [overlay_instance.savesIndicator release];

    savedGame = YES;
    stopSpinningProgress();
}

void saveFinishedSynching() {
    [UIView beginAnimations:@"fading from save synch" context:NULL];
    [UIView setAnimationDuration:1];
    overlay_instance.view.backgroundColor = [UIColor clearColor];
    overlay_instance.view.alpha = 1;
    overlay_instance.view.userInteractionEnabled = YES;
    [UIView commitAnimations];

    [overlay_instance.savesIndicator stopAnimating];
    [overlay_instance.savesIndicator performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];

    gameRunning = YES;
    savedGame = NO;
}

void updateVisualsNewTurn(void) {
    [overlay_instance.amvc updateAmmoVisuals];
}

// dummy function to prevent linkage fail
int SDL_main(int argc, char **argv) {
    return 0;
}
