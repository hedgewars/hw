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

@synthesize username, password, musicSwitch, soundsSwitch, altDamageSwitch, 
	    volumeSlider, volumeLabel, table, volumeCell, buttonContainer;


-(void) loadView {
	self.musicSwitch = [[UISwitch alloc] init];
	self.soundsSwitch = [[UISwitch alloc] init];
	self.altDamageSwitch = [[UISwitch alloc] init];
	[self.soundsSwitch addTarget:self action:@selector(sameValueSwitch) forControlEvents:UIControlEventValueChanged];
	[self.musicSwitch addTarget:self action:@selector(checkValueSwitch) forControlEvents:UIControlEventValueChanged];

	[super loadView];
}

-(void) viewDidLoad {
	NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"];
	
	needsReset = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {	
		NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
		username.text = [data objectForKey:@"username"];
		password.text = [data objectForKey:@"password"];
		if (1 == [[data objectForKey:@"music"] intValue]) {
			musicSwitch.on = YES;
		} else {
			musicSwitch.on = NO;
		}
		if (1 == [[data objectForKey:@"sounds"] intValue]) {
			soundsSwitch.on = YES;
		} else {
			soundsSwitch.on = NO;
		}
		if (1 == [[data objectForKey:@"alternate"] intValue]) {
			altDamageSwitch.on = YES;
		} else {
			altDamageSwitch.on = NO;
		}		
		
		[volumeSlider setValue:[[data objectForKey:@"volume"] intValue] animated:NO];
		[data release];
	} else {
		[NSException raise:@"File NOT found" format:@"The file settings.plist was not found at %@", filePath];
	}
	
	NSString *tmpVol = [[NSString alloc] initWithFormat:@"%d", (int) volumeSlider.value];
	volumeLabel.text = tmpVol;
	[tmpVol release];
	
	username.textColor = [UIColor grayColor];
	password.textColor = [UIColor grayColor];
	volumeLabel.textColor = [UIColor grayColor];
	table.backgroundColor = [UIColor clearColor];
	table.allowsSelection = NO;
	buttonContainer.backgroundColor = [UIColor clearColor];
	table.tableFooterView = buttonContainer;
	
	[super viewDidLoad];
}

-(void) viewDidUnload {
	self.username = nil;
	self.password = nil;
	self.musicSwitch = nil;
	self.soundsSwitch = nil;
	self.altDamageSwitch = nil;
	self.volumeLabel = nil;
	self.volumeSlider = nil;
	self.table = nil;
	self.volumeCell = nil;
	self.buttonContainer = nil;
	[super viewDidUnload];
}

//- (void)applicationWillTerminate:(NSNotification *)notification {
-(void) viewWillDisappear:(BOOL)animated {
	if (!needsReset) {
		NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] init];
		NSString *tmpMus = (musicSwitch.on) ? @"1" : @"0";
		NSString *tmpEff = (soundsSwitch.on) ? @"1" : @"0";
		NSString *tmpAlt = (altDamageSwitch.on) ? @"1" : @"0";
		
		[saveDict setObject:username.text forKey:@"username"];
		[saveDict setObject:password.text forKey:@"password"];
		[saveDict setObject:tmpMus forKey:@"music"];
		[saveDict setObject:tmpEff forKey:@"sounds"];
		[saveDict setObject:tmpAlt forKey:@"alternate"];
		[saveDict setObject:volumeLabel.text forKey:@"volume"];
		
		[saveDict writeToFile:[[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"] atomically:YES];
		[saveDict release];
	}
	[super viewWillDisappear:animated];
}

-(void) dealloc {
	[username release];
	[password release];
	[musicSwitch release];
	[soundsSwitch release];
	[altDamageSwitch release];
	[volumeLabel release];
	[volumeSlider release];
	[table release];
	[volumeCell release];
	[buttonContainer release];
	[super dealloc];
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

// update the value of the label when slider is updated
-(IBAction) sliderChanged: (id) sender {
	UISlider *slider = (UISlider *)sender;
	int progress = slider.value;
	NSString *newLabel = [[NSString alloc] initWithFormat:@"%d",progress];
	self.volumeLabel.text = newLabel;
	[newLabel release];
}

// set music off when sound is turned off
-(void) sameValueSwitch {
	if (YES == self.musicSwitch.on) {
		[musicSwitch setOn:NO animated:YES];
	}
}

// don't enable music when sound is off
-(void) checkValueSwitch {
	if (NO == self.soundsSwitch.on) {
		[musicSwitch setOn:!musicSwitch.on animated:YES];
	}
}

#pragma mark -
#pragma mark UIActionSheet Methods
-(IBAction) deleteData: (id)sender {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you reeeeeally sure?"
								 delegate:self
							cancelButtonTitle:@"Well, maybe not..."
						   destructiveButtonTitle:@"Sure, let's start over"
							otherButtonTitles:nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
}

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
	if ([actionSheet cancelButtonIndex] != buttonIndex) {
		needsReset = YES;
		
		// get the document dirctory
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		// get the content of the directory
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *dirContent = [fm directoryContentsAtPath:documentsDirectory];
		NSError *error;
		
		// delete data
		for (NSString *fileName in dirContent) {
			[fm removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:fileName] error:&error];
		}
		
		// force resetting
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Hit Home Button to Exit" 
								  message:@"\nEverything is gone!\nNow you need to restart the game..." 
								 delegate:self
							cancelButtonTitle:nil
							otherButtonTitles:nil];
		[anAlert show];
		[anAlert release];
	}
}

#pragma mark -
#pragma mark TableView Methods
#define kNetworkFields 0
#define kAudioFields 1
#define kOtherFields 2

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kNetworkFields:
			return 2;
			break;
		case kAudioFields:
			return 3;
			break;
		case kOtherFields:
			return 1;
			break;
		default:
			NSLog(@"Warning: unset case value for numberOfRowsInSection!");
			break;
	}
	return 0;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"systemSettingsCell";
	
	UITableViewCell *cell;
	if ( !(kAudioFields == [indexPath section] && 2 == [indexPath row]) ){
		cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (nil == cell) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
						       reuseIdentifier:cellIdentifier] autorelease];
		}
	}
	
	switch ([indexPath section]) {
		case kNetworkFields:
			switch ([indexPath row]) {
				case 0:
					cell.textLabel.text = NSLocalizedString(@"Nickname", @"");
					cell.accessoryView = username;
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"Password", @"");
					cell.accessoryView = password;
					break;
				default:
					NSLog(@"Warning: unset case value in kNetworkFields section!");
					break;
			}
			break;
		case kAudioFields:
			switch ([indexPath row]) {
				case 0:
					cell.accessoryView = soundsSwitch;
					cell.textLabel.text = NSLocalizedString(@"Sound", @"");
					break;
				case 1:
					cell.accessoryView = musicSwitch;
					cell.textLabel.text = NSLocalizedString(@"Music", @"");
					break;
				case 2:
					cell = volumeCell;
					break;
				default:
					NSLog(@"Warning: unset case value in kAudioFields section!");
					break;
			}
			break;
		case kOtherFields:
			cell.accessoryView = altDamageSwitch;
			cell.textLabel.text = NSLocalizedString(@"Alternate Damage", @"");
			break;
		default:
			break;
	}
	
	return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *containerView =	[[[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 50)] autorelease];
	UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 20, 300, 40)] autorelease];
	headerLabel.textColor = [UIColor lightGrayColor];
	headerLabel.shadowColor = [UIColor blackColor];
	headerLabel.shadowOffset = CGSizeMake(0, 1);
	headerLabel.font = [UIFont boldSystemFontOfSize:20];
	headerLabel.backgroundColor = [UIColor clearColor];

	switch (section) {
		case kNetworkFields:
			headerLabel.text = NSLocalizedString(@"Network Configuration", @"Network Configuration");
			break;
		case kAudioFields:
			headerLabel.text = NSLocalizedString(@"Audio Preferences", @"");
			break;
		case kOtherFields:
			headerLabel.text = NSLocalizedString(@"Other Settings", @"");
			break;
		default:
			NSLog(@"Warning: unset case value in titleForHeaderInSection!");
			headerLabel.text = @"!!!";
			break;
	}
	
	[containerView addSubview:headerLabel];
	return containerView;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (kAudioFields == [indexPath section] && 2 == [indexPath row])
		return volumeCell.frame.size.height;
	else
		return table.rowHeight;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 57.0;
}

@end
