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


#import "ObjcExports.h"

#pragma mark -
#pragma mark functions called by pascal code
BOOL inline isApplePhone(void) {
    return (IS_IPAD() == NO);
}

void startLoadingIndicator(void) {
    // this is the first ojbc function called by engine, so we have to initialize some variables here

    if ([HWUtils gameType] == gtSave) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

        /*
        overlay_instance.view.backgroundColor = [UIColor blackColor];
        overlay_instance.view.alpha = 0.75;
        overlay_instance.view.userInteractionEnabled = NO;
        */
    }
    /*
    CGPoint center = overlay_instance.view.center;
    CGPoint loaderCenter = ([HWUtils gameType] == gtSave) ? center : CGPointMake(center.x, center.y * 5/3);

    overlay_instance.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    overlay_instance.loadingIndicator.hidesWhenStopped = YES;
    overlay_instance.loadingIndicator.center = loaderCenter;
    overlay_instance.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                                         UIViewAutoresizingFlexibleRightMargin |
                                                         UIViewAutoresizingFlexibleTopMargin |
                                                         UIViewAutoresizingFlexibleBottomMargin;
    [overlay_instance.loadingIndicator startAnimating];
    [overlay_instance.view addSubview:overlay_instance.loadingIndicator];
    */
}

void stopLoadingIndicator(void) {
    //HW_zoomSet(1.7);
    if ([HWUtils gameType] != gtSave) {
        //[overlay_instance.loadingIndicator stopAnimating];
        //[overlay_instance.loadingIndicator removeFromSuperview];
        [HWUtils setGameStatus:gsInGame];
    }
    // mark the savefile as valid, eg it's been loaded correctly
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"saveIsValid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

void saveFinishedSynching(void) {
    /*
    [UIView beginAnimations:@"fading from save synch" context:NULL];
    [UIView setAnimationDuration:1];
    overlay_instance.view.backgroundColor = [UIColor clearColor];
    overlay_instance.view.alpha = 1;
    overlay_instance.view.userInteractionEnabled = YES;
    [UIView commitAnimations];

    [overlay_instance.loadingIndicator stopAnimating];
    [overlay_instance.loadingIndicator performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
    */

    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [HWUtils setGameStatus:gsInGame];
}


// dummy function to prevent linkage fail
int SDL_main(int argc, char **argv) {
    return 0;
}
