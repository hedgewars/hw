//
//  MainMenuViewController.m
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainMenuViewController.h"
#import "SDL_uikitappdelegate.h"

@implementation MainMenuViewController

@synthesize passandplayButton, netplayButton, storeButton, versionLabel;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void) viewDidLoad {
	self.versionLabel.text = @"Hedgewars version 0.9.13-dev";
    [super viewDidLoad];
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) return YES;
	else return NO;
}

/*
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}
*/

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	self.passandplayButton = nil;
	self.netplayButton = nil;
	self.storeButton = nil;
	self.versionLabel = nil;
}

- (void)dealloc {
	[passandplayButton release];
	[netplayButton release];
	[storeButton release];
	[versionLabel release];
    [super dealloc];
}

// disable the buttons when to prevent launching twice the game
-(void) viewWillDisappear:(BOOL)animated {
	passandplayButton.enabled = NO;
	netplayButton.enabled = NO;
	storeButton.enabled = NO;
	[super viewWillDisappear:animated];
}

-(void) viewWillAppear:(BOOL)animated {
	passandplayButton.enabled = YES;
	netplayButton.enabled = YES;
	storeButton.enabled = YES;
	[super viewWillAppear:animated];
}

-(IBAction) startPlaying {
	[[SDLUIKitDelegate sharedAppDelegate] startSDLgame];
}

-(IBAction) notYetImplemented {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Yet Implemented"
									message:@"Sorry, this feature is not yet implemented"
									delegate:nil
									cancelButtonTitle:@"Well, don't worry"
									otherButtonTitles:nil];
	[alert show];
	[alert release];
}

@end
