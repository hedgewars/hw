//
//  SettingsViewController.m
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "SDL_uikitappdelegate.h"

@implementation SettingsViewController

@synthesize username, password, musicOn, effectsOn, altDamageOn, volumeSlider, volumeLabel;

-(void) viewDidLoad {
	NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {	
		NSUserDefaults *data = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
		username.text = [data objectForKey:@"username"];
		password.text = [data objectForKey:@"password"];
		if (1 == [[data objectForKey:@"music"] intValue]) {
			musicOn.on = YES;
		} else {
			musicOn.on = NO;
		}
		if (1 == [[data objectForKey:@"effects"] intValue]) {
			effectsOn.on = YES;
		} else {
			effectsOn.on = NO;
		}
		if (1 == [[data objectForKey:@"alternate"] intValue]) {
			altDamageOn.on = YES;
		} else {
			altDamageOn.on = NO;
		}		
		
		[volumeSlider setValue:[[data objectForKey:@"volume"] intValue] animated:NO];
		
		NSString *tmpVol = [[NSString alloc] initWithFormat:@"%d", (int) volumeSlider.value];
		volumeLabel.text = tmpVol;
		[tmpVol release];
	} else {
		[NSException raise:@"File NOT found" format:@"The file settings.plist was not found at %@", filePath];
	}
/*	
	UIApplication *app = [UIApplication sharedApplication];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillTerminate:)
												 name:UIApplicationWillTerminateNotification
											   object:app];
*/
	[super viewDidLoad];
}

-(void) viewDidUnload {
	self.username = nil;
	self.password = nil;
	self.musicOn = nil;
	self.effectsOn = nil;
	self.altDamageOn = nil;
	self.volumeLabel = nil;
	self.volumeSlider = nil;
	[super viewDidUnload];
}

//- (void)applicationWillTerminate:(NSNotification *)notification {
-(void) viewWillDisappear:(BOOL)animated {
	NSMutableDictionary *saveArray = [[NSMutableDictionary alloc] init];
	NSString *tmpMus = (musicOn.on) ? @"1" : @"0";
	NSString *tmpEff = (effectsOn.on) ? @"1" : @"0";
	NSString *tmpAlt = (altDamageOn.on) ? @"1" : @"0";
	
	[saveArray setObject:username.text forKey:@"username"];
	[saveArray setObject:password.text forKey:@"password"];
	[saveArray setObject:tmpMus forKey:@"music"];
	[saveArray setObject:tmpEff forKey:@"effects"];
	[saveArray setObject:tmpAlt forKey:@"alternate"];
	[saveArray setObject:volumeLabel.text forKey:@"volume"];
	
	[saveArray writeToFile:[[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"] atomically:YES];
	[saveArray release];
	[super viewWillDisappear:animated];
}
 
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

// makes the keyboard go away when background is tapped
-(IBAction) backgroundTap: (id)sender {
	[username resignFirstResponder];
	[password resignFirstResponder];
}

// makes the keyboard go away when "Done" is tapped
-(IBAction) textFieldDoneEditing: (id)sender {
	[sender resignFirstResponder];
}

-(IBAction) sliderChanged: (id) sender {
	UISlider *slider = (UISlider *)sender;
	int progress = slider.value;
	NSString *newLabel = [[NSString alloc] initWithFormat:@"%d",progress];
	self.volumeLabel.text = newLabel;
	[newLabel release];
}

-(void) dealloc {
	[username release];
	[password release];
	[musicOn release];
	[effectsOn release];
	[altDamageOn release];
	[volumeLabel release];
	[volumeSlider release];
    [super dealloc];
}


@end
