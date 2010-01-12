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
#import "gameSetup.h"

#ifdef main
#undef main
#endif

extern int SDL_main(int argc, char *argv[]);
BOOL isServerRunning = NO;

int main (int argc, char **argv) {
	int i;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	/* store arguments */
	forward_argc = argc;
	forward_argv = (char **)malloc(argc * sizeof(char *));
	for (i = 0; i < argc; i++) {
		forward_argv[i] = malloc( (strlen(argv[i])+1) * sizeof(char));
		strcpy(forward_argv[i], argv[i]);
	}

	/* Give over control to run loop, SDLUIKitDelegate will handle most things from here */
	UIApplicationMain(argc, argv, NULL, @"SDLUIKitDelegate");
	
	[pool release];
}

@implementation SDLUIKitDelegate

@synthesize window, windowID, controller;

/* convenience method */
+(SDLUIKitDelegate *)sharedAppDelegate {
	/* the delegate is set in UIApplicationMain(), which is garaunteed to be called before this method */
	return (SDLUIKitDelegate *)[[UIApplication sharedApplication] delegate];
}

void preSDL_main(){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	SDL_main(forward_argc, forward_argv);

	[pool release];
}

- (void) startSDLgame {
	pthread_t threadID;

	if (NO == isServerRunning) {
		// don't start another server because the port is already bound
		pthread_create (&threadID, NULL, (void *) (*engineProtocolThread), NULL);
		pthread_detach (threadID);
		isServerRunning = YES;
	}

	setupArgsForLocalPlay();
	
	// remove the current view to free resources
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.5];
	controller.view.alpha = 0;
	[UIView commitAnimations];
	[controller.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5];
	//[controller.view removeFromSuperview];
	
	/* run the user's application, passing argc and argv */
	NSLog(@"Game is launching...");
	/*pthread_create (&threadID, NULL, (void *) (*preSDL_main), NULL);
	pthread_detach (threadID);*/
	int res = SDL_main(forward_argc, forward_argv);

	// can't reach here yet
	NSLog(@"Game exited with status %d", res);

	//[self performSelector:@selector(makeNewView) withObject:nil afterDelay:0.0];
	/* exit, passing the return status from the user's application */
	//exit(exit_status);
}

// override the direct execution of SDL_main to allow us to implement the frontend (even using a nib)
-(void) applicationDidFinishLaunching:(UIApplication *)application {
	[application setStatusBarHidden:YES animated:NO];

	/* Set working directory to resource path */
	[[NSFileManager defaultManager] changeCurrentDirectoryPath: [[NSBundle mainBundle] resourcePath]];
//#import "SoundEffect.h"	
//	SoundEffect *erasingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Erase" ofType:@"caf"]];
//	SoundEffect *selectSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Select" ofType:@"caf"]];
	[window addSubview:controller.view];
	[window makeKeyAndVisible];
}

-(void) applicationWillTerminate:(UIApplication *)application {
	/* free the memory we used to hold copies of argc and argv */
	int i;
	for (i=0; i < forward_argc; i++) {
		free(forward_argv[i]);
	}
	free(forward_argv);	
	SDL_SendQuit();
	/* hack to prevent automatic termination.  See SDL_uikitevents.m for details */
	// have to remove this otherwise game goes on when pushing the home button
	//longjmp(*(jump_env()), 1);
}

-(void) applicationWillResignActive:(UIApplication*)application
{
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	SDL_SendWindowEvent(self.windowID, SDL_WINDOWEVENT_MINIMIZED, 0, 0);
}

-(void) applicationDidBecomeActive:(UIApplication*)application
{
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	SDL_SendWindowEvent(self.windowID, SDL_WINDOWEVENT_RESTORED, 0, 0);
}

/*
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	NSLog(@"Rotating...");
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
*/

void IPH_returnFrontend (void) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[[SDLUIKitDelegate sharedAppDelegate].window viewWithTag:54867] removeFromSuperview];
	[[SDLUIKitDelegate sharedAppDelegate].window addSubview:[SDLUIKitDelegate sharedAppDelegate].controller.view];
//	[[SDLUIKitDelegate sharedAppDelegate].window makeKeyAndVisible];
	NSLog(@"Game exited...");
//	pthread_exit(NULL);
	[pool release];
	exit(0);
//	while(1);	//prevent exiting	
}


-(void) dealloc {
	[controller release];
	[window release];
	[super dealloc];
}

@end
