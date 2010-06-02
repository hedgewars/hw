//
//  SettingsViewController.m
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GeneralSettingsViewController.h"
#import "CommodityFunctions.h"

@implementation GeneralSettingsViewController
@synthesize settingsDictionary, textFieldBeingEdited, musicSwitch, soundSwitch, altDamageSwitch;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark textfield methods
// return to previous table
-(void) cancel:(id) sender {
    if (textFieldBeingEdited != nil)
        [self.textFieldBeingEdited resignFirstResponder];
}

// set the new value
-(BOOL) save:(id) sender {
    if (textFieldBeingEdited != nil) {
        if (textFieldBeingEdited.tag == 0) {
            [self.settingsDictionary setObject:textFieldBeingEdited.text forKey:@"username"];
        } else {
            [self.settingsDictionary setObject:textFieldBeingEdited.text forKey:@"password"];
        }
        
        isWriteNeeded = YES;
        [self.textFieldBeingEdited resignFirstResponder];
        return YES;
    }
    return NO;
}

// the textfield is being modified, update the navigation controller
-(void) textFieldDidBeginEditing:(UITextField *)aTextField{   
    self.textFieldBeingEdited = aTextField;
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",@"from the settings table")
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",@"from the settings table")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
}

// the textfield has been modified, check for empty strings and restore original navigation bar
-(void) textFieldDidEndEditing:(UITextField *)aTextField{
    self.textFieldBeingEdited = nil;
    self.navigationItem.rightBarButtonItem = self.navigationItem.backBarButtonItem;
    self.navigationItem.leftBarButtonItem = nil;
}

// limit the size of the field to 64 characters like in original frontend
-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    int limit = 64;
    return !([textField.text length] > limit && [string length] > range.length);
}


#pragma mark -
#pragma mark View Lifecycle
-(void) viewDidLoad {
	[super viewDidLoad];
    self.musicSwitch = [[UISwitch alloc] init];
	self.soundSwitch = [[UISwitch alloc] init];
	self.altDamageSwitch = [[UISwitch alloc] init];
	[self.soundSwitch addTarget:self action:@selector(alsoTurnOffMusic:) forControlEvents:UIControlEventValueChanged];
	[self.musicSwitch addTarget:self action:@selector(dontTurnOnMusic:) forControlEvents:UIControlEventValueChanged];
	[self.altDamageSwitch addTarget:self action:@selector(justUpdateDictionary:) forControlEvents:UIControlEventValueChanged];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_FILE()];
    self.settingsDictionary = dictionary;
    [dictionary release];
}

-(void) viewWillAppear:(BOOL)animated {
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
    isWriteNeeded = NO;
    
    musicSwitch.on = [[settingsDictionary objectForKey:@"music"] boolValue];
    soundSwitch.on = [[settingsDictionary objectForKey:@"sound"] boolValue];
    altDamageSwitch.on = [[settingsDictionary objectForKey:@"alternate"] boolValue];
    
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (isWriteNeeded) {
       	NSLog(@"writing preferences to file");
        [self.settingsDictionary writeToFile:SETTINGS_FILE() atomically:YES];
        isWriteNeeded = NO;
    }
}

#pragma mark -
// if the sound system is off, turn off also the background music 
-(void) alsoTurnOffMusic:(id) sender {
    [self.settingsDictionary setObject:[NSNumber numberWithBool:soundSwitch.on] forKey:@"sound"];
	if (YES == self.musicSwitch.on) {
		[musicSwitch setOn:NO animated:YES];
        [self.settingsDictionary setObject:[NSNumber numberWithBool:musicSwitch.on] forKey:@"music"];
	}
    isWriteNeeded = YES;
}

// if the sound system is off, don't enable background music 
-(void) dontTurnOnMusic:(id) sender {
	if (NO == self.soundSwitch.on) {
		[musicSwitch setOn:NO animated:YES];
	} else {
        [self.settingsDictionary setObject:[NSNumber numberWithBool:musicSwitch.on] forKey:@"music"];
        isWriteNeeded = YES;
    }
}

-(void) justUpdateDictionary:(id) sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    [self.settingsDictionary setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"alternate"];
    isWriteNeeded = YES;
}

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
			break;
	}
	return 0;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"systemSettingsCell";
	NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        if (section == kNetworkFields) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-15, 10, 100, 25)];
            label.textAlignment = UITextAlignmentRight;
            label.backgroundColor = [UIColor clearColor];
            label.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 2];
            if (row == 0) 
                label.text = NSLocalizedString(@"Nickname","from the settings table");
            else 
                label.text = NSLocalizedString(@"Password","from the settings table");
            [cell.contentView addSubview:label];
            [label release];
            
            UITextField *aTextField = [[UITextField alloc] initWithFrame:
                                       CGRectMake(110, 12, (cell.frame.size.width + cell.frame.size.width/3) - 90, 25)];
            aTextField.clearsOnBeginEditing = NO;
            aTextField.returnKeyType = UIReturnKeyDone;
            aTextField.adjustsFontSizeToFitWidth = YES;
            aTextField.delegate = self;
            aTextField.tag = row;
            aTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            [aTextField addTarget:self action:@selector(save:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [cell.contentView addSubview:aTextField];
            [aTextField release];
        }
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.image = nil;
    
    UITextField *aTextField;
    switch (section) {
        case kNetworkFields:
            for (UIView *oneView in cell.contentView.subviews) 
                if ([oneView isMemberOfClass:[UITextField class]]) 
                    aTextField = (UITextField *)oneView;

            switch (row) {
				case 0:                    
                    aTextField.placeholder = NSLocalizedString(@"Insert your username (if you have one)",@"");
                    aTextField.text = [self.settingsDictionary objectForKey:@"username"];
					break;
				case 1:                    
                    aTextField.placeholder = NSLocalizedString(@"Insert your password",@"");
                    aTextField.text = [self.settingsDictionary objectForKey:@"password"];
                    aTextField.secureTextEntry = YES;
					break;
				default:
					break;
			}
			break;
            
		case kAudioFields:
			switch (row) {
				case 0:
					cell.textLabel.text = NSLocalizedString(@"Sound", @"");
					cell.accessoryView = soundSwitch;
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"Music", @"");
					cell.accessoryView = musicSwitch;
					break;
				default:
					break;
			}
			break;
            
		case kOtherFields:
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


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (kNetworkFields == [indexPath section]) {
        cell = [aTableView cellForRowAtIndexPath:indexPath];
        for (UIView *oneView in cell.contentView.subviews) {
            if ([oneView isMemberOfClass:[UITextField class]]) {
                textFieldBeingEdited = (UITextField *)oneView;
                [textFieldBeingEdited becomeFirstResponder];
            }
        }
        [aTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    self.settingsDictionary = nil;
	self.textFieldBeingEdited = nil;
	self.musicSwitch = nil;
	self.soundSwitch = nil;
	self.altDamageSwitch = nil;
	[super viewDidUnload];
    MSG_DIDUNLOAD();
}

-(void) dealloc {
    [settingsDictionary release];
	[textFieldBeingEdited release];
	[musicSwitch release];
	[soundSwitch release];
	[altDamageSwitch release];
	[super dealloc];
}


@end
