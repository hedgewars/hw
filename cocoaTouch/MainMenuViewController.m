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

// in case we don't want SDL_mixer...
//#import "SoundEffect.h"	
//SoundEffect *erasingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Erase" ofType:@"caf"]];
//SoundEffect *selectSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Select" ofType:@"caf"]];


@implementation MainMenuViewController

@synthesize versionLabel, settingsViewController, mainView;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	if (nil == self.settingsViewController.view.superview) {
		self.settingsViewController = nil;
		[settingsViewController release];
	}
}

-(void) viewDidLoad {
	[NSThread detachNewThreadSelector:@selector(checkFirstRun) toTarget:self withObject:nil];
	
	char *ver="test";
	//HW_versionInfo(NULL, &ver);
	self.versionLabel.text = [[NSString stringWithUTF8String:ver] autorelease];
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

-(void) checkFirstRun {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"];
	if (!([[NSFileManager defaultManager] fileExistsAtPath:filePath])) {
		// file not present, means that also other files are absent
		NSLog(@"First time run, creating settings files");
		
		// show a popup with an indicator to make the user wait
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"One-time Preferences Configuration",@"")
								message:nil
							       delegate:nil
						      cancelButtonTitle:nil
						      otherButtonTitles:nil];
		[alert show];
		
		UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] 
						      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		indicator.center = CGPointMake(alert.bounds.size.width / 2, alert.bounds.size.height - 50);
		[indicator startAnimating];
		[alert addSubview:indicator];
		[indicator release];
		
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
		
		// memory cleanup
		[alert dismissWithClickedButtonIndex:0 animated:YES];
		[alert release];
	}
	[pool release];
	[NSThread exit];
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
			SettingsViewController *controller = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController-iPad"
												      bundle:nil];
			self.settingsViewController = controller;
			[controller release];
		}
		self.settingsViewController.view.frame = CGRectMake(0, -257, 480, 278);
		self.settingsViewController.parentView = self.mainView;

		[UIView beginAnimations:@"Settings SwitchView" context:NULL];
		[UIView setAnimationDuration:1];

		self.settingsViewController.view.frame = CGRectMake(0, 21, 480, 278);
		self.mainView.frame = CGRectMake(0, 299, 480, 278);
		[UIView commitAnimations];
		
		[self.view insertSubview:settingsViewController.view atIndex:0];
	}

}

@end
