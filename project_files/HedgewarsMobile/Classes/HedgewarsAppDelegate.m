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


#import "HedgewarsAppDelegate.h"
#import "MainMenuViewController.h"


@implementation SDLUIKitDelegate (customDelegate)

// hijack the the SDL_UIKitAppDelegate to use the UIApplicationDelegate we implement here
+(NSString *)getAppDelegateClassName {
    return @"HedgewarsAppDelegate";
}

@end

@implementation HedgewarsAppDelegate
@synthesize mainViewController, uiwindow;

#pragma mark -
#pragma mark AppDelegate methods
-(id) init {
    if ((self = [super init])) {
        mainViewController = nil;
        uiwindow = nil;
    }
    return self;
}

-(void) dealloc {
    [mainViewController release];
    [uiwindow release];
    [super dealloc];
}

// override the direct execution of SDL_main to allow us to implement our own frontend
-(void) postFinishLaunch {
    [self performSelector:@selector(hideLaunchScreen) withObject:nil afterDelay:0.0];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.uiwindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.uiwindow.backgroundColor = [UIColor blackColor];

    NSString *controllerName = (IS_IPAD() ? @"MainMenuViewController-iPad" : @"MainMenuViewController-iPhone");
    self.mainViewController = [[MainMenuViewController alloc] initWithNibName:controllerName bundle:nil];
    self.uiwindow.rootViewController = self.mainViewController;
    [self.mainViewController release];

    [self.uiwindow makeKeyAndVisible];
}

-(void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [HWUtils releaseCache];
    // don't stop music if it is playing
    if ([HWUtils isGameLaunched]) {
        [[AudioManagerController mainManager] didReceiveMemoryWarning];
        HW_memoryWarningCallback();
    }
    MSG_MEMCLEAN();
    // don't clean mainMenuViewController here!!!
}

// true multitasking with SDL works only on 4.2 and above; we close the game to avoid a black screen at return
-(void) applicationWillResignActive:(UIApplication *)application {
    if ([HWUtils isGameLaunched] && [[[UIDevice currentDevice] systemVersion] floatValue] < 4.2f)
        HW_terminate(NO);

    [super applicationWillResignActive:application];
}

@end
