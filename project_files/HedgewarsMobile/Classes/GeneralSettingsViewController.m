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
@synthesize settingsDictionary;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View Lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_FILE()];
    self.settingsDictionary = dictionary;
    [dictionary release];
}

-(void) viewWillAppear:(BOOL)animated {
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
    
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];    
    [self.settingsDictionary writeToFile:SETTINGS_FILE() atomically:YES];
}

#pragma mark -
-(void) switchValueChanged:(id) sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    UISwitch *theOtherSwitch = nil;
    
    switch (theSwitch.tag) {
        case 10:    //soundSwitch
            // this turn off also the switch below
            [self.settingsDictionary setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"sound"];
            [self.settingsDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"music"];
            theOtherSwitch = (UISwitch *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]].accessoryView;
            [theOtherSwitch setOn:NO animated:YES];
            break;
        case 20:    //musicSwitch
            // if switch above is off, never turn on
            if (NO == [[self.settingsDictionary objectForKey:@"sound"] boolValue]) {
                [self.settingsDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"music"];
                theOtherSwitch = (UISwitch *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]].accessoryView;
                [theOtherSwitch setOn:NO animated:YES];
            } else
                [self.settingsDictionary setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"music"];
            break;
        case 30:    //alternateSwitch
            [self.settingsDictionary setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"alternate"];
            break;
        default:
            DLog(@"Wrong tag");
            break;
    }
}

-(void) saveTextFieldValue:(NSString *)textString withTag:(NSInteger) tagValue {
    if (tagValue == 40)
        [self.settingsDictionary setObject:textString forKey:@"username"];
    else
        [self.settingsDictionary setObject:textString forKey:@"password"];
}

#pragma mark -
#pragma mark TableView Methods
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:     // user and pass
            return 2;
            break;
        case 1:     // audio
            return 2;
            break;
        case 2:     // alternate damage
            return 1;
            break;
        default:
            break;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = NSLocalizedString(@"Network Configuration", @"");
            break;
        case 1:
            sectionTitle = NSLocalizedString(@"Audio Preferences", @"");
            break;
        case 2:
            sectionTitle = NSLocalizedString(@"Other Settings", @"");
            break;
        default:
            DLog(@"Nope");
            break;
    }
    return sectionTitle;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier0 = @"Cell0";
    static NSString *cellIdentifier1 = @"Cell1";
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    
    UITableViewCell *cell = nil;
    EditableCellView *editableCell = nil;
    if (section == 0) {
        editableCell = (EditableCellView *)[aTableView dequeueReusableCellWithIdentifier:cellIdentifier0];
        if (nil == editableCell) {
            editableCell = [[[EditableCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier0] autorelease];
            editableCell.minimumCharacters = 0;
            editableCell.delegate = self;
            editableCell.textField.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            editableCell.textField.textColor = [UIColor lightGrayColor];
        }
        
        if (row == 0) {
            editableCell.titleLabel.text = NSLocalizedString(@"Nickname","from the settings table");
            editableCell.textField.placeholder = NSLocalizedString(@"Insert your username (if you have one)",@"");
            editableCell.textField.text = [self.settingsDictionary objectForKey:@"username"];
            editableCell.textField.secureTextEntry = NO;
            editableCell.tag = 40;
        } else {
            editableCell.titleLabel.text = NSLocalizedString(@"Password","from the settings table");
            editableCell.textField.placeholder = NSLocalizedString(@"Insert your password",@"");
            editableCell.textField.text = [self.settingsDictionary objectForKey:@"password"];
            editableCell.textField.secureTextEntry = YES;
            editableCell.tag = 50;
        }
        
        editableCell.accessoryView = nil;
        cell = editableCell;
    } else {
        cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier1];
        if (nil == cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier1] autorelease];
            UISwitch *theSwitch = [[UISwitch alloc] init];
            [theSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = theSwitch;
            [theSwitch release];
        }
        
        UISwitch *switchContent = (UISwitch *)cell.accessoryView;
        if (section == 1) {
            if (row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Sound", @"");
                switchContent.on = [[self.settingsDictionary objectForKey:@"sound"] boolValue];
                switchContent.tag = 10;
            } else {
                cell.textLabel.text = NSLocalizedString(@"Music", @"");
                switchContent.on = [[self.settingsDictionary objectForKey:@"music"] boolValue];
                switchContent.tag = 20;
            }
        } else {
            cell.textLabel.text = NSLocalizedString(@"Alternate Damage", @"");
            switchContent.on = [[self.settingsDictionary objectForKey:@"alternate"] boolValue];
            switchContent.tag = 30;
        }
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.image = nil;
    
    return cell;
}

/*
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *containerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 50)] autorelease];
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
    if (0 == [indexPath section]) {
        EditableCellView *cell = (EditableCellView *)[aTableView cellForRowAtIndexPath:indexPath];
        [cell replyKeyboard];
    }
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.settingsDictionary = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [settingsDictionary release];
    [super dealloc];
}

@end
