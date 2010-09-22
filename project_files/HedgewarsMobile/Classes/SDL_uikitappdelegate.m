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
@synthesize mainViewController;

// convenience method
+(SDLUIKitDelegate *)sharedAppDelegate {
    // the delegate is set in UIApplicationMain(), which is guaranteed to be called before this method
    return (SDLUIKitDelegate *)[[UIApplication sharedApplication] delegate];
}

-(id) init {
    if (self = [super init]){
        mainViewController = nil;
        isInGame = NO;
    }
    return self;
}

-(void) dealloc {
    [mainViewController release];
    [super dealloc];
}

// main routine for calling the actual game engine
-(void) startSDLgame:(NSDictionary *)gameDictionary {
    UIWindow *aWin = [[[UIApplication sharedApplication] windows] objectAtIndex:0];

    UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, aWin.frame.size.height, aWin.frame.size.width)];
    blackView.opaque = YES;
    blackView.backgroundColor = [UIColor blackColor];
    [aWin addSubview:blackView];

    // pull out useful configuration info from various files
    GameSetup *setup = [[GameSetup alloc] initWithDictionary:gameDictionary];
    NSNumber *isNetGameNum = [gameDictionary objectForKey:@"netgame"];
    
    if ([isNetGameNum boolValue] == NO)
        [setup startThread:@"engineProtocol"];
    const char **gameArgs = [setup getSettings:[gameDictionary objectForKey:@"savefile"]];
    [setup release];

    // since the sdlwindow is not yet created, we add the overlayController with a delay
    [self performSelector:@selector(displayOverlayLater:) withObject:isNetGameNum afterDelay:0.1];

    // this is the pascal fuction that starts the game (wrapped around isInGame)
    isInGame = YES;
    Game(gameArgs);
    isInGame = NO;
    free(gameArgs);

    [aWin makeKeyAndVisible];
    [UIView beginAnimations:@"fading in from ingame" context:NULL];
    [UIView setAnimationDuration:1];
    blackView.alpha = 0;
    [UIView commitAnimations];
    [blackView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
    [blackView performSelector:@selector(release) withObject:nil afterDelay:1]; 
}

-(void) displayOverlayLater:(NSNumber *)isNetGame {
    // overlay with controls, become visible later, with a transparency effect
    OverlayViewController *overlayController = [[OverlayViewController alloc] initWithNibName:@"OverlayViewController" bundle:nil];

    // keyWindow is the frontmost window
    [[[UIApplication sharedApplication] keyWindow] addSubview:overlayController.view];
    [overlayController release];
}

// override the direct execution of SDL_main to allow us to implement the frontend (or even using a nib)
-(void) applicationDidFinishLaunching:(UIApplication *)application {
    [application setStatusBarHidden:YES];

    UIWindow *uiwindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.mainViewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPad" bundle:nil];
    else
        self.mainViewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPhone" bundle:nil];

    [uiwindow addSubview:self.mainViewController.view];
    [self.mainViewController release];
    uiwindow.backgroundColor = [UIColor blackColor];
    [uiwindow makeKeyAndVisible];

    // set working directory to resource path
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
}

-(void) applicationWillTerminate:(UIApplication *)application {
    SDL_SendQuit();

    if (isInGame) {
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
    if (isInGame) {
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
    if (isInGame) {
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
