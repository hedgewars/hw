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

//#import "SoundEffect.h"	
//	SoundEffect *erasingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Erase" ofType:@"caf"]];
//	SoundEffect *selectSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Select" ofType:@"caf"]];


#ifdef main
#undef main
#endif

int main (int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"SDLUIKitDelegate");
    [pool release];
    return retVal;
}

@implementation SDLUIKitDelegate

@synthesize uiwindow, window, controller;

/* convenience method */
+(SDLUIKitDelegate *)sharedAppDelegate {
	/* the delegate is set in UIApplicationMain(), which is guaranteed to be called before this method */
	return (SDLUIKitDelegate *)[[UIApplication sharedApplication] delegate];
}

-(id) init {
	self = [super init];
	self.uiwindow = nil;
	self.window = NULL;
	self.controller = nil;
	return self;
}

-(void) dealloc {
	[controller release];
	[uiwindow release];
	[super dealloc];
}

#pragma mark -
#pragma mark Custom stuff
-(IBAction) startSDLgame {
	NSAutoreleasePool *internal_pool = [[NSAutoreleasePool alloc] init];

	GameSetup *setup = [[GameSetup alloc] init];
	[setup startThread:@"engineProtocol"];

	// remove the current view to free resources
	[UIView beginAnimations:@"removing main controller" context:NULL];
	[UIView setAnimationDuration:1];
	controller.view.alpha = 0;
	[UIView commitAnimations];
	[controller.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];

	NSLog(@"Game is launching...");
	const char **gameArgs = [setup getSettings];
	
	// direct execution or thread? check the one that gives most fps
	// library or call SDL_main? pascal quits at the end of the main
	Game(gameArgs);
	
	free(gameArgs);
	NSLog(@"Game is exting...");

	[setup release];

	[UIView beginAnimations:@"inserting main controller" context:NULL];
	[UIView setAnimationDuration:1];
	controller.view.alpha = 1;
	[UIView commitAnimations];
	
	[uiwindow addSubview:controller.view];
	[uiwindow makeKeyAndVisible];
	
	[internal_pool release];
}

-(BOOL) checkFirstRun {
	BOOL isFirstRun = NO;
	
	NSString *filePath = [self dataFilePath:@"settings.plist"];
	if (!([[NSFileManager defaultManager] fileExistsAtPath:filePath])) {
		isFirstRun = YES;
		// file not present, let's create it
		NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] init];
	
		[saveDict setObject:@"" forKey:@"username"];
		[saveDict setObject:@"" forKey:@"password"];
		[saveDict setObject:@"1" forKey:@"music"];
		[saveDict setObject:@"1" forKey:@"sounds"];
		[saveDict setObject:@"0" forKey:@"alternate"];
		[saveDict setObject:@"100" forKey:@"volume"];
	
		[saveDict writeToFile:filePath atomically:YES];
		[saveDict release];
	}
	return isFirstRun;
}

-(NSString *)dataFilePath: (NSString *)fileName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:fileName];
}

-(void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Running low on memory"
							message:@"Will try to free some memory but app may crash"
						       delegate:nil
					      cancelButtonTitle:@"Ok"
					      otherButtonTitles:nil ];
	[alert show];
	[alert release];
}
#pragma mark -
#pragma mark SDLUIKitDelegate methods
// override the direct execution of SDL_main to allow us to implement the frontend (even using a nib)
-(void) applicationDidFinishLaunching:(UIApplication *)application {
	[application setStatusBarHidden:YES animated:NO];

	[self checkFirstRun];
	/* Set working directory to resource path */
	[[NSFileManager defaultManager] changeCurrentDirectoryPath: [[NSBundle mainBundle] resourcePath]];

	[uiwindow addSubview:controller.view];
	[uiwindow makeKeyAndVisible];
}

-(void) applicationWillTerminate:(UIApplication *)application {
	SDL_SendQuit();
	/* hack to prevent automatic termination.  See SDL_uikitevents.m for details */
	// have to remove this otherwise game goes on when pushing the home button
	//longjmp(*(jump_env()), 1);
}

-(void) applicationWillResignActive:(UIApplication*)application {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	SDL_SendWindowEvent(self.window, SDL_WINDOWEVENT_MINIMIZED, 0, 0);
}

-(void) applicationDidBecomeActive:(UIApplication*)application {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	SDL_SendWindowEvent(self.window, SDL_WINDOWEVENT_RESTORED, 0, 0);
}

/*
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	NSLog(@"Rotating...");
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
*/

@end
