/*
 SDL - Simple DirectMedia Layer
 Copyright (C) 1997-2011 Sam Lantinga

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

 Sam Lantinga, mods for Hedgewars by Vittorio Giovara
 slouken@libsdl.org, vittorio.giovara@gmail.com
*/

#import "HedgewarsAppDelegate.h"
#import "PascalImports.h"
#import "ObjcExports.h"
#import "CommodityFunctions.h"
#import "GameSetup.h"
#import "MainMenuViewController.h"
#import "OverlayViewController.h"
#import "Appirater.h"
#include <unistd.h>

#ifdef main
#undef main
#endif

#define BLACKVIEW_TAG 17935
#define SECONDBLACKVIEW_TAG 48620
#define VALGRIND "/opt/fink/bin/valgrind"

int main (int argc, char *argv[]) {
#ifdef VALGRIND_REXEC
    // Using the valgrind build config, rexec ourself in valgrind
    // from http://landonf.bikemonkey.org/code/iphone/iPhone_Simulator_Valgrind.20081224.html
    if (argc < 2 || (argc >= 2 && strcmp(argv[1], "-valgrind") != 0))
        execl(VALGRIND, VALGRIND, "--leak-check=full", "--dsymutil=yes", argv[0], "-valgrind", NULL);
#endif
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"HedgewarsAppDelegate");
    [pool release];
    return retVal;
}

int SDL_main(int argc, char **argv) {
    // dummy function to prevent linkage fail
    return 0;
}

@implementation HedgewarsAppDelegate
@synthesize mainViewController, overlayController, uiwindow, secondWindow, isInGame;

// convenience method
+(HedgewarsAppDelegate *)sharedAppDelegate {
    return (HedgewarsAppDelegate *)[[UIApplication sharedApplication] delegate];
}

-(id) init {
    if (self = [super init]){
        mainViewController = nil;
        uiwindow = nil;
        secondWindow = nil;
        isInGame = NO;
    }
    return self;
}

-(void) dealloc {
    [mainViewController release];
    [overlayController release];
    [uiwindow release];
    [secondWindow release];
    [super dealloc];
}

// main routine for calling the actual game engine
-(NSArray *)startSDLgame:(NSDictionary *)gameDictionary {
    UIWindow *gameWindow;
    if (IS_DUALHEAD())
        gameWindow = self.secondWindow;
    else
        gameWindow = self.uiwindow;

    UIView *blackView = [[UIView alloc] initWithFrame:gameWindow.frame];
    blackView.backgroundColor = [UIColor blackColor];
    blackView.opaque = YES;
    blackView.tag = BLACKVIEW_TAG;
    [gameWindow addSubview:blackView];
    if (IS_DUALHEAD()) {
        blackView.alpha = 0;
        [UIView beginAnimations:@"fading to game first" context:NULL];
        [UIView setAnimationDuration:1];
        blackView.alpha = 1;
        [UIView commitAnimations];

        UIView *secondBlackView = [[UIView alloc] initWithFrame:self.uiwindow.frame];
        secondBlackView.backgroundColor = [UIColor blackColor];
        secondBlackView.opaque = YES;
        secondBlackView.tag = SECONDBLACKVIEW_TAG;
        secondBlackView.alpha = 0;
        [self.uiwindow addSubview:secondBlackView];
        [UIView beginAnimations:@"fading to game second" context:NULL];
        [UIView setAnimationDuration:1];
        secondBlackView.alpha = 1;
        [UIView commitAnimations];
        [secondBlackView release];
    }
    [blackView release];


    // pull out useful configuration info from various files
    GameSetup *setup = [[GameSetup alloc] initWithDictionary:gameDictionary];
    NSNumber *isNetGameNum = [gameDictionary objectForKey:@"netgame"];

    [NSThread detachNewThreadSelector:@selector(engineProtocol)
                             toTarget:setup
                           withObject:nil];

    NSNumber *menuStyle = [NSNumber numberWithBool:setup.menuStyle];
    NSNumber *orientation = [[gameDictionary objectForKey:@"game_dictionary"] objectForKey:@"orientation"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          isNetGameNum,@"net",
                          menuStyle,@"menu",
                          orientation,@"orientation",
                          nil];
    [self performSelector:@selector(displayOverlayLater:) withObject:dict afterDelay:1];

    // need to set again [gameDictionary objectForKey:@"savefile"] because if it's empty it means it's a normal game
    const char **gameArgs = [setup getGameSettings:[gameDictionary objectForKey:@"savefile"]];
    self.isInGame = YES;
    // this is the pascal fuction that starts the game
    Game(gameArgs);
    self.isInGame = NO;
    free(gameArgs);

    NSArray *stats = setup.statsArray;
    [setup release];


    [self.uiwindow makeKeyAndVisible];
    [self.uiwindow bringSubviewToFront:self.mainViewController.view];

    UIView *refBlackView = [gameWindow viewWithTag:BLACKVIEW_TAG];
    UIView *refSecondBlackView = [self.uiwindow viewWithTag:SECONDBLACKVIEW_TAG];
    [UIView beginAnimations:@"fading in from ingame" context:NULL];
    [UIView setAnimationDuration:1];
    refBlackView.alpha = 0;
    refSecondBlackView.alpha = 0;
    [UIView commitAnimations];
    [refBlackView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
    [refSecondBlackView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:2];

    return stats;
}

// overlay with controls, become visible later, with a transparency effect since the sdlwindow is not yet created
-(void) displayOverlayLater:(id) object {
    NSDictionary *dict = (NSDictionary *)object;
    self.overlayController = [[OverlayViewController alloc] initWithNibName:@"OverlayViewController" bundle:nil];
    self.overlayController.isNetGame = [[dict objectForKey:@"net"] boolValue];
    self.overlayController.useClassicMenu = [[dict objectForKey:@"menu"] boolValue];
    self.overlayController.initialOrientation = [[dict objectForKey:@"orientation"] intValue];

    UIWindow *gameWindow;
    if (IS_DUALHEAD())
        gameWindow = self.uiwindow;
    else
        gameWindow = [[UIApplication sharedApplication] keyWindow];
    [gameWindow addSubview:self.overlayController.view];
}

// override the direct execution of SDL_main to allow us to implement our own frontend
-(void) postFinishLaunch {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [Appirater appLaunched];

    self.uiwindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    if (IS_IPAD())
        self.mainViewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPad" bundle:nil];
    else
        self.mainViewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPhone" bundle:nil];

    [self.uiwindow addSubview:self.mainViewController.view];
    [self.mainViewController release];
    self.uiwindow.backgroundColor = [UIColor blackColor];
    [self.uiwindow makeKeyAndVisible];

    // check for dual monitor support
    if (IS_DUALHEAD()) {
        DLog(@"dual head mode ftw");
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

-(void) applicationWillTerminate:(UIApplication *)application {
    if (self.isInGame)
        HW_terminate(YES);

    [super applicationWillTerminate:application];
}

-(void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    // don't clean mainMenuViewController here!!!
    MSG_MEMCLEAN();
    print_free_memory();
}

-(void) applicationWillResignActive:(UIApplication *)application {
    [super applicationWillResignActive: application];

    UIDevice* device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] &&
         device.multitaskingSupported &&
         self.isInGame) {
        // let's try to be permissive with multitasking here...
        NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_FILE()];
        if ([[settings objectForKey:@"multitasking"] boolValue])
            HW_suspend();
        else {
            // so the game returns to the configuration view
            if (isGameRunning())
                HW_terminate(NO);
            else {
                // while screen is loading you can't call HW_terminate() so we close the app
                [self applicationWillTerminate:application];
            }
        }
        [settings release];
    }
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
    [super applicationDidBecomeActive:application];

    UIDevice* device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] &&
         device.multitaskingSupported &&
         self.isInGame) {
        HW_resume();
    }
}

@end
