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

#import <pthread.h>
#import "SDL_uikitappdelegate.h"
#import "SDL_uikitopenglview.h"
#import "SDL_events_c.h"
#import "jumphack.h"
#import "SDL_video.h"
#import "GameSetup.h"
#import "PascalImports.h"
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
    if (argc < 2 || (argc >= 2 && strcmp(argv[1], "-valgrind") != 0)) {
        execl(VALGRIND, VALGRIND, "--leak-check=full", "--show-reachable=yes", argv[0], "-valgrind", NULL);
    }
#endif

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"SDLUIKitDelegate");
	[pool release];
	return retVal;
}

@implementation SDLUIKitDelegate
@synthesize uiwindow, window;

// convenience method
+(SDLUIKitDelegate *)sharedAppDelegate {
	// the delegate is set in UIApplicationMain(), which is guaranteed to be called before this method
	return (SDLUIKitDelegate *)[[UIApplication sharedApplication] delegate];
}

-(id) init {
	if (self = [super init]){
        self.uiwindow = nil;
        self.window = NULL;
        viewController = nil;
        isInGame = NO;
        return self;
    } else 
        return nil;
}

-(void) dealloc {
    SDL_DestroyWindow(self.window);
    [viewController release];
	[uiwindow release];
	[super dealloc];
}

// main routine for calling the actual game engine
-(IBAction) startSDLgame {
    [viewController disappear];

    // pull out useful configuration info from various files
	GameSetup *setup = [[GameSetup alloc] init];
	[setup startThread:@"engineProtocol"];
	const char **gameArgs = [setup getSettings];
	[setup release];
    
    OverlayViewController *overlayController;
    // overlay with controls, become visible after 2 seconds
    overlayController = [[OverlayViewController alloc] initWithNibName:@"OverlayViewController" bundle:nil];
    
    [uiwindow addSubview:overlayController.view];
    [overlayController release];

    isInGame = YES;
	Game(gameArgs); // this is the pascal fuction that starts the game
    isInGame = NO;
    
    free(gameArgs);
    [overlayController.view removeFromSuperview];
    
    [viewController appear];
}

// override the direct execution of SDL_main to allow us to implement the frontend (even using a nib)
-(void) applicationDidFinishLaunching:(UIApplication *)application {
	//[application setStatusBarHidden:YES animated:NO];
    //[application setStatusBarHidden:YES withAnimation:NO];
    [application setStatusBarHidden:YES];
    [application setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];  
    
	self.uiwindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.uiwindow.backgroundColor = [UIColor blackColor];
	
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        viewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPad" bundle:nil];
    else
        viewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController-iPhone" bundle:nil];
	[uiwindow addSubview:viewController.view];
	
	// Set working directory to resource path
	[[NSFileManager defaultManager] changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];

	[uiwindow makeKeyAndVisible];
	[uiwindow layoutSubviews];
}

-(void) applicationWillTerminate:(UIApplication *)application {
	SDL_SendQuit();
    if (isInGame) {
        HW_terminate(YES);
        // hack to prevent automatic termination. See SDL_uikitevents.m for details
        longjmp(*(jump_env()), 1);
    }
}

-(void) applicationWillResignActive:(UIApplication *)application {
	//NSLog(@"%@", NSStringFromSelector(_cmd));
    if (isInGame) HW_pause();
	//SDL_SendWindowEvent(self.window, SDL_WINDOWEVENT_MINIMIZED, 0, 0);
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
	//NSLog(@"%@", NSStringFromSelector(_cmd));
    if (isInGame) HW_pause();
	//SDL_SendWindowEvent(self.window, SDL_WINDOWEVENT_RESTORED, 0, 0);
}

@end
