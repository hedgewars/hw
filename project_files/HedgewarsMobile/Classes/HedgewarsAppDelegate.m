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


#import "HedgewarsAppDelegate.h"
#import "PascalImports.h"
#import "ObjcExports.h"
#import "CommodityFunctions.h"
#import "MainMenuViewController.h"
#import "AVFoundation/AVAudioPlayer.h"
#include <unistd.h>


@implementation SDLUIKitDelegate (customDelegate)

+(NSString *)getAppDelegateClassName {
    return @"HedgewarsAppDelegate";
}

@end

@implementation HedgewarsAppDelegate
@synthesize mainViewController, uiwindow, secondWindow, isInGame, backgroundMusic;

// convenience method
+(HedgewarsAppDelegate *)sharedAppDelegate {
    return (HedgewarsAppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark -
#pragma mark Music control
+(void) playBackgroundMusic {
    if ([HedgewarsAppDelegate sharedAppDelegate].backgroundMusic == nil)
        [HedgewarsAppDelegate loadBackgroundMusic];
    [[HedgewarsAppDelegate sharedAppDelegate].backgroundMusic play];
}

+(void) pauseBackgroundMusic {
    [[HedgewarsAppDelegate sharedAppDelegate].backgroundMusic pause];
}

+(void) stopBackgroundMusic {
    [[HedgewarsAppDelegate sharedAppDelegate].backgroundMusic stop];
}

+(void) loadBackgroundMusic {
    NSString *musicString = [[NSBundle mainBundle] pathForResource:@"hwclassic" ofType:@"mp3"];
    AVAudioPlayer *background = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:musicString] error:nil];

    background.delegate = nil;
    background.volume = 0.4f;
    background.numberOfLoops = -1;
    [background prepareToPlay];
    [HedgewarsAppDelegate sharedAppDelegate].backgroundMusic = background;
    [background release];
}

#pragma mark -
#pragma mark AppDelegate methods
-(id) init {
    if (self = [super init]){
        mainViewController = nil;
        uiwindow = nil;
        secondWindow = nil;
        isInGame = NO;
        backgroundMusic = nil;
    }
    return self;
}

-(void) dealloc {
    [mainViewController release];
    [uiwindow release];
    [secondWindow release];
    [backgroundMusic release];
    [super dealloc];
}

// override the direct execution of SDL_main to allow us to implement our own frontend
-(void) postFinishLaunch {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.uiwindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    NSString *controllerName = (IS_IPAD() ? @"MainMenuViewController-iPad" : @"MainMenuViewController-iPhone");
    self.mainViewController = [[MainMenuViewController alloc] initWithNibName:controllerName bundle:nil];

    [self.uiwindow addSubview:self.mainViewController.view];
    [self.mainViewController release];
    self.uiwindow.backgroundColor = [UIColor blackColor];
    [self.uiwindow makeKeyAndVisible];

    // check for dual monitor support
    if (IS_DUALHEAD()) {
        DLog(@"Dualhead mode");
        self.secondWindow = [[UIWindow alloc] initWithFrame:[[[UIScreen screens] objectAtIndex:1] bounds]];
        self.secondWindow.backgroundColor = [UIColor blackColor];
        self.secondWindow.screen = [[UIScreen screens] objectAtIndex:1];
        UIImage *titleImage = [UIImage imageWithContentsOfFile:@"title.png"];
        UIImageView *titleView = [[UIImageView alloc] initWithImage:titleImage];
        titleView.center = self.secondWindow.center;
        [self.secondWindow addSubview:titleView];
        [titleView release];
        [self.secondWindow makeKeyAndVisible];
    }
}

-(void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    // don't stop music when it is playing
    if (self.isInGame) {
        [self.backgroundMusic stop];
        self.backgroundMusic = nil;
        MSG_MEMCLEAN();
    }
    print_free_memory();
    // don't clean mainMenuViewController here!!!
}

-(void) applicationWillResignActive:(UIApplication *)application {
    // true multitasking with sdl works only on 4.2 and above; we close the game to avoid a black screen at return
    if (self.isInGame && ([[[UIDevice currentDevice] systemVersion] floatValue] < 4.2f))
        HW_terminate(NO);
    [super applicationWillResignActive:application];
}


@end
