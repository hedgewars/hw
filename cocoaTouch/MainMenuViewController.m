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

@synthesize versionLabel, settingsViewController, mainView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	if (nil == self.settingsViewController.view.superview) {
		self.settingsViewController = nil;
	}
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void) viewDidLoad {
	self.versionLabel.text = @"0.9.13-dev";
	[super viewDidLoad];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	self.versionLabel = nil;
}

- (void)dealloc {
	[versionLabel release];
	[settingsViewController release];
	[super dealloc];
}

// disable the buttons when to prevent launching twice the game
-(void) viewWillDisappear:(BOOL)animated {
	self.mainView.userInteractionEnabled = NO;
	[super viewWillDisappear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
	self.mainView.userInteractionEnabled = YES;
	[super viewDidAppear:animated];
}

#pragma mark -
#pragma mark Action buttons
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

-(IBAction) switchViews:(id)sender {

	// view not displayed or not created
	if (nil == self.settingsViewController.view.superview) {
		// view not created
		if (nil == self.settingsViewController) {
			SettingsViewController *controller = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController"
												      bundle:nil];
			self.settingsViewController = controller;
			self.settingsViewController.parentView = self.mainView;
			[controller release];
		}
		self.settingsViewController.view.frame = CGRectMake(0, -320, 480, 320);

		[UIView beginAnimations:@"View Switch" context:NULL];
		[UIView setAnimationDuration:3];
		[UIView setAnimationDuration:UIViewAnimationCurveEaseOut];
		self.settingsViewController.view.frame = CGRectMake(0, 0, 480, 320);
		self.mainView.frame = CGRectMake(0, 320, 480, 320);
		
		[self.view addSubview:settingsViewController.view];
		[UIView commitAnimations];
	}

}

@end
