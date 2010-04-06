//
//  SettingsViewController.m
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GeneralSettingsViewController.h"
#import "SDL_uikitappdelegate.h"

@implementation GeneralSettingsViewController
@synthesize dataDict, username, password, musicSwitch, soundSwitch, altDamageSwitch;

-(void) dealloc {
    [dataDict release];
	[username release];
	[password release];
	[musicSwitch release];
	[soundSwitch release];
	[altDamageSwitch release];
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark View Lifecycle
-(void) viewDidLoad {
    self.musicSwitch = [[UISwitch alloc] init];
	self.soundSwitch = [[UISwitch alloc] init];
	self.altDamageSwitch = [[UISwitch alloc] init];
	[self.soundSwitch addTarget:self action:@selector(sameValueSwitch) forControlEvents:UIControlEventValueChanged];
	[self.musicSwitch addTarget:self action:@selector(checkValueSwitch) forControlEvents:UIControlEventValueChanged];
    
    NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    self.dataDict = dictionary;
    [dictionary release];
	[super viewDidLoad];
}

-(void) viewDidUnload {
    self.dataDict = nil;
	self.username = nil;
	self.password = nil;
	self.musicSwitch = nil;
	self.soundSwitch = nil;
	self.altDamageSwitch = nil;
	[super viewDidUnload];
}

-(void) viewWillAppear:(BOOL)animated {
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
    
    username = [NSString stringWithString:[dataDict objectForKey:@"username"]];
    password = [NSString stringWithString:[dataDict objectForKey:@"password"]];   
    
    if (1 == [[dataDict objectForKey:@"music"] intValue]) {
        musicSwitch.on = YES;
    } else {
        musicSwitch.on = NO;
    }
    if (1 == [[dataDict objectForKey:@"sounds"] intValue]) {
        soundSwitch.on = YES;
    } else {
        soundSwitch.on = NO;
    }
    if (1 == [[dataDict objectForKey:@"alternate"] intValue]) {
        altDamageSwitch.on = YES;
    } else {
        altDamageSwitch.on = NO;
    }

    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
	NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] init];
	NSString *tmpMus = (musicSwitch.on) ? @"1" : @"0";
	NSString *tmpEff = (soundSwitch.on) ? @"1" : @"0";
	NSString *tmpAlt = (altDamageSwitch.on) ? @"1" : @"0";
	 
	[saveDict setObject:username forKey:@"username"];
	[saveDict setObject:password forKey:@"password"];
	[saveDict setObject:tmpMus forKey:@"music"];
	[saveDict setObject:tmpEff forKey:@"sounds"];
	[saveDict setObject:tmpAlt forKey:@"alternate"];
	
    if (![dataDict isEqualToDictionary:saveDict]) {
       	NSLog(@"writing preferences to file");
        [saveDict writeToFile:[[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"] atomically:YES];
        // this will also relase the previous dictionary
        self.dataDict = saveDict;
    }
	[saveDict release];
}

#pragma mark -
// set music off when sound is turned off
-(void) sameValueSwitch {
	if (YES == self.musicSwitch.on) {
		[musicSwitch setOn:NO animated:YES];
	}
}

// don't enable music when sound is off
-(void) checkValueSwitch {
	if (NO == self.soundSwitch.on) {
		[musicSwitch setOn:!musicSwitch.on animated:YES];
	}
}

/*
// makes the keyboard go away when background is tapped
-(IBAction) backgroundTap: (id)sender {
//	[username resignFirstResponder];
//	[password resignFirstResponder];
}

// makes the keyboard go away when "Done" is tapped
-(IBAction) textFieldDoneEditing: (id)sender {
	[sender resignFirstResponder];
}
*/

/*
#pragma mark -
#pragma mark UIActionSheet Methods
-(IBAction) deleteData: (id)sender {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you reeeeeally sure?", @"")
								 delegate:self
							cancelButtonTitle:NSLocalizedString(@"Well, maybe not...", @"")
						   destructiveButtonTitle:NSLocalizedString(@"As sure as I can be!", @"")
							otherButtonTitles:nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
}

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
	if ([actionSheet cancelButtonIndex] != buttonIndex) {
		// get the documents dirctory
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
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Hit Home Button to Exit", @"")
								  message:NSLocalizedString(@"\nEverything is gone!\nNow you need to restart the game...", @"")
								 delegate:self
							cancelButtonTitle:nil
							otherButtonTitles:nil];
		[anAlert show];
		[anAlert release];
	}
}
*/

#pragma mark -
#pragma mark TableView Methods
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kNetworkFields:
			return 2;
			break;
		case kAudioFields:
			return 2;
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
	static NSString *cellIdentifier1 = @"systemSettingsCell1";
	static NSString *cellIdentifier2 = @"systemSettingsCell2";
	
	UITableViewCell *cell = nil;
	
	switch ([indexPath section]) {
		case kNetworkFields:
            cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier1];
            if (nil == cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                           reuseIdentifier:cellIdentifier1] autorelease];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
			switch ([indexPath row]) {
				case 0:                    
					cell.textLabel.text = NSLocalizedString(@"Nickname", @"");
                    if ([username isEqualToString:@""]) {
                        cell.detailTextLabel.text = @"insert username...";
                        cell.detailTextLabel.font = [UIFont italicSystemFontOfSize:[UIFont systemFontSize]];
                        cell.detailTextLabel.textColor = [UIColor grayColor];
                    } else {
                        cell.detailTextLabel.text = username;
                    }
					break;
				case 1:                    
					cell.textLabel.text = NSLocalizedString(@"Password", @"");
                    if ([password isEqualToString:@""]) {
                        cell.detailTextLabel.text = @"insert password...";
                        cell.detailTextLabel.font = [UIFont italicSystemFontOfSize:[UIFont systemFontSize]];
                        cell.detailTextLabel.textColor = [UIColor grayColor];
                    } else {
                        cell.detailTextLabel.text = @"••••••••";
                    }
					break;
				default:
					NSLog(@"Warning: unset case value in kNetworkFields section!");
					break;
			}
			break;
            
		case kAudioFields:
            cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier2];
            if (nil == cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:cellIdentifier2] autorelease];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

			switch ([indexPath row]) {
				case 0:
					cell.textLabel.text = NSLocalizedString(@"Sound", @"");
					cell.accessoryView = soundSwitch;
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"Music", @"");
					cell.accessoryView = musicSwitch;
					break;
				default:
					NSLog(@"Warning: unset case value in kAudioFields section!");
					break;
			}
            // this makes the row not selectable
			break;
            
		case kOtherFields:
            cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier2];
            if (nil == cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:cellIdentifier2] autorelease];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.text = NSLocalizedString(@"Alternate Damage", @"");
			cell.accessoryView = altDamageSwitch;
			break;
		default:
			break;
	}
	return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
		case kNetworkFields:
			sectionTitle = NSLocalizedString(@"Network Configuration", @"");
			break;
		case kAudioFields:
			sectionTitle = NSLocalizedString(@"Audio Preferences", @"");
			break;
		case kOtherFields:
			sectionTitle = NSLocalizedString(@"Other Settings", @"");
			break;
		default:
			NSLog(@"Nope");
			break;
	}
    return sectionTitle;
}

/*
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
			headerLabel.text = NSLocalizedString(@"Network Configuration", @"");
			break;
		case kAudioFields:
			headerLabel.text = NSLocalizedString(@"Audio Preferences", @"");
			break;
		case kOtherFields:
			headerLabel.text = NSLocalizedString(@"Other Settings", @"");
			break;
		default:
			NSLog(@"Warning: unset case value in titleForHeaderInSection!");
			headerLabel.text = @"!";
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
*/

@end
