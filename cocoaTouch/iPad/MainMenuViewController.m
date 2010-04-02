//
//  MainMenuViewController.m
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainMenuViewController.h"
#import "SDL_uikitappdelegate.h"
#import "PascalImports.h"
#import "SplitViewRootController.h"


@implementation MainMenuViewController
@synthesize cover;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
    [cover release];
	[super dealloc];
}

-(void) viewDidUnload {
    self.cover = nil;
	[super viewDidUnload];
}

-(void) viewDidLoad {
    // initialize some files the first time we load the game
	[NSThread detachNewThreadSelector:@selector(checkFirstRun) toTarget:self withObject:nil];
    // listen to request to remove the modalviewcontroller
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissModalViewController)
                                                 name: @"dismissModalView" 
                                               object:nil];

	[super viewDidLoad];
}

// this is called to verify whether it's the first time the app is launched
// if it is it blocks user interaction with an alertView until files are created
-(void) checkFirstRun {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"];
	if (!([[NSFileManager defaultManager] fileExistsAtPath:filePath])) {
		// file not present, means that also other files are absent
		NSLog(@"First time run, creating settings files");
		
		// show a popup with an indicator to make the user wait
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please wait",@"")
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
		[alert show];
		[alert release];

		UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] 
                                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		indicator.center = CGPointMake(alert.bounds.size.width / 2, alert.bounds.size.height - 50);
		[indicator startAnimating];
		[alert addSubview:indicator];
		[indicator release];
		
        // create Default Team.plist
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *teamsDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"Teams/"];
		[[NSFileManager defaultManager] createDirectoryAtPath:teamsDirectory 
                                  withIntermediateDirectories:NO 
                                                   attributes:nil 
                                                        error:NULL];

        NSMutableArray *hedgehogs = [[NSMutableArray alloc] init];

        for (int i = 0; i < 8; i++) {
            NSString *hogName = [[NSString alloc] initWithFormat:@"hedgehog %d",i];
            NSDictionary *hog = [[NSDictionary alloc] initWithObjectsAndKeys:@"100",@"health",@"0",@"level",
                                 hogName,@"hogname",@"NoHat",@"hat",nil];
            [hogName release];
            [hedgehogs addObject:hog];
            [hog release];
        }
        
        NSDictionary *defaultTeam = [[NSDictionary alloc] initWithObjectsAndKeys:@"4421353",@"color",@"0",@"hash",
                                     @"Default Team",@"teamname",@"Statue",@"grave",@"Plane",@"fort",
                                     @"Default",@"voicepack",@"hedgewars",@"flag",hedgehogs,@"hedgehogs",nil];
        [hedgehogs release];
        NSString *defaultTeamFile = [teamsDirectory stringByAppendingString:@"Default Team.plist"];
        [defaultTeam writeToFile:defaultTeamFile atomically:YES];
        [defaultTeam release];
        
		// create settings.plist
		NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] init];
	
		[saveDict setObject:@"" forKey:@"username"];
		[saveDict setObject:@"" forKey:@"password"];
		[saveDict setObject:@"1" forKey:@"music"];
		[saveDict setObject:@"1" forKey:@"sounds"];
		[saveDict setObject:@"0" forKey:@"alternate"];
	
		[saveDict writeToFile:filePath atomically:YES];
		[saveDict release];
		
		// create other files
        
        // ok let the user take control
		[alert dismissWithClickedButtonIndex:0 animated:YES];
	}
	[pool release];
	[NSThread exit];
}

#pragma mark -
-(void) appear {
    [[SDLUIKitDelegate sharedAppDelegate].uiwindow addSubview:self.view];
    [self release];
    
    [UIView beginAnimations:@"inserting main controller" context:NULL];
	[UIView setAnimationDuration:1];
	self.view.alpha = 1;
	[UIView commitAnimations];
    
    [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(hideBehind) userInfo:nil repeats:NO];
}

-(void) disappear {
    if (nil != cover)
        [cover release];
    
    [UIView beginAnimations:@"removing main controller" context:NULL];
	[UIView setAnimationDuration:1];
	self.view.alpha = 0;
	[UIView commitAnimations];
    
    [self retain];
    [self.view removeFromSuperview];
}

// this is a silly way to hide the sdl contex that remained active
-(void) hideBehind {
    if (nil == cover) {
        cover= [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        cover.backgroundColor = [UIColor blackColor];
    }
    [[SDLUIKitDelegate sharedAppDelegate].uiwindow insertSubview:cover belowSubview:self.view];
}

#pragma mark -
-(IBAction) switchViews:(id) sender {
    UIButton *button = (UIButton *)sender;
    SplitViewRootController *splitViewController;
    UIAlertView *alert;
    
    switch (button.tag) {
        case 0:
            [[SDLUIKitDelegate sharedAppDelegate] startSDLgame];
            break;
        case 2:
            // for now this controller is just to simplify code management
            splitViewController = [[SplitViewRootController alloc] initWithNibName:nil bundle:nil];
            splitViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:splitViewController animated:YES];
            break;
        default:
            alert = [[UIAlertView alloc] initWithTitle:@"Not Yet Implemented"
                                               message:@"Sorry, this feature is not yet implemented"
                                              delegate:nil
                                     cancelButtonTitle:@"Well, don't worry"
                                     otherButtonTitles:nil];
            [alert show];
            [alert release];
            break;
    }
}

-(void) dismissModalViewController {
    [self dismissModalViewControllerAnimated:YES];
}

@end
