/*
 SDL - Simple DirectMedia Layer
 Copyright (C) 1997-2009 Sam Lantinga

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

#import "SDL_uikitappdelegate.h"
#import "SDL_uikitopenglview.h"
#import "SDL_uikitwindow.h"
#import "SDL_events_c.h"
#import "../SDL_sysvideo.h"
#import "jumphack.h"
#import "SDL_video.h"
#import "SDL_mixer.h"
#import "PascalImports.h"
#import "CommodityFunctions.h"
#import "GameSetup.h"
#import "MainMenuViewController.h"
#import "OverlayViewController.h"

#ifdef main
#undef main
#endif

#define BLACKVIEW_TAG 17935
#define SECONDBLACKVIEW_TAG 48620
#define VALGRIND "/opt/valgrind/bin/valgrind"

int main (int argc, char *argv[]) {
#ifdef VALGRIND_REXEC
    // Using the valgrind build config, rexec ourself in valgrind
    // from http://landonf.bikemonkey.org/code/iphone/iPhone_Simulator_Valgrind.20081224.html
    if (argc < 2 || (argc >= 2 && strcmp(argv[1], "-valgrind") != 0))
        execl(VALGRIND, VALGRIND, "--leak-check=full", argv[0], "-valgrind", NULL);
#endif

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"SDLUIKitDelegate");
    [pool release];
    return retVal;
}

@implementation SDLUIKitDelegate
@synthesize mainViewController, uiwindow, secondWindow, isInGame;

// convenience method
+(SDLUIKitDelegate *)sharedAppDelegate {
    // the delegate is set in UIApplicationMain(), which is guaranteed to be called before this method
    return (SDLUIKitDelegate *)[[UIApplication sharedApplication] delegate];
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
    [uiwindow release];
    [secondWindow release];
    [super dealloc];
}

// main routine for calling the actual game engine
-(void) startSDLgame:(NSDictionary *)gameDictionary {
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
    
    if ([isNetGameNum boolValue] == NO)
        [setup startThread:@"engineProtocol"];
    const char **gameArgs = [setup getSettings:[gameDictionary objectForKey:@"savefile"]];
    NSNumber *menuStyle = [NSNumber numberWithBool:setup.menuStyle];
    [setup release];

    // since the sdlwindow is not yet created, we add the overlayController with a delay
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:isNetGameNum,@"net",menuStyle,@"menu",nil];
    [self performSelector:@selector(displayOverlayLater:) withObject:dict afterDelay:1];

    // this is the pascal fuction that starts the game (wrapped around isInGame)
    self.isInGame = YES;
    Game(gameArgs);
    self.isInGame = NO;
    free(gameArgs);

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
    [refSecondBlackView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
}

// overlay with controls, become visible later, with a transparency effect
-(void) displayOverlayLater:(id) object {
    NSDictionary *dict = (NSDictionary *)object;
    OverlayViewController *overlayController = [[OverlayViewController alloc] initWithNibName:@"OverlayViewController" bundle:nil];
    overlayController.isNetGame = [[dict objectForKey:@"net"] boolValue];
    overlayController.useClassicMenu = [[dict objectForKey:@"menu"] boolValue];
    
    UIWindow *gameWindow;
    if (IS_DUALHEAD())
        gameWindow = self.uiwindow;
    else
        gameWindow = [[UIApplication sharedApplication] keyWindow];
    [gameWindow addSubview:overlayController.view];
    [overlayController release];
}

// override the direct execution of SDL_main to allow us to implement the frontend (or even using a nib)
-(void) applicationDidFinishLaunching:(UIApplication *)application {
    [application setStatusBarHidden:YES];

    self.uiwindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    if (IS_IPAD())
        self.mainViewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPad" bundle:nil];
    else
        self.mainViewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPhone" bundle:nil];

    [self.uiwindow addSubview:self.mainViewController.view];
    [self.mainViewController release];
    self.uiwindow.backgroundColor = [UIColor blackColor];
    [self.uiwindow makeKeyAndVisible];

    // set working directory to resource path
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];

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
    SDL_SendQuit();

    if (self.isInGame) {
        HW_terminate(YES);
        // hack to prevent automatic termination. See SDL_uikitevents.m for details
        longjmp(*(jump_env()), 1);
    }
}

-(void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    // don't clean mainMenuViewController here!!!
    MSG_MEMCLEAN();
    print_free_memory();
}

-(void) applicationWillResignActive:(UIApplication *)application {
    if (self.isInGame) {
        HW_pause();

        // Send every window on every screen a MINIMIZED event.
        SDL_VideoDevice *_this = SDL_GetVideoDevice();
        if (!_this)
            return;

        int i;
        for (i = 0; i < _this->num_displays; i++) {
            const SDL_VideoDisplay *display = &_this->displays[i];
            SDL_Window *window;
            for (window = display->windows; window != nil; window = window->next)
                SDL_SendWindowEvent(window, SDL_WINDOWEVENT_MINIMIZED, 0, 0);
        }
    }
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
    if (self.isInGame) {
        HW_pause();

        // Send every window on every screen a RESTORED event.
        SDL_VideoDevice *_this = SDL_GetVideoDevice();
        if (!_this)
            return;

        int i;
        for (i = 0; i < _this->num_displays; i++) {
            const SDL_VideoDisplay *display = &_this->displays[i];
            SDL_Window *window;
            for (window = display->windows; window != nil; window = window->next)
                SDL_SendWindowEvent(window, SDL_WINDOWEVENT_RESTORED, 0, 0);
        }
    }
}

@end
