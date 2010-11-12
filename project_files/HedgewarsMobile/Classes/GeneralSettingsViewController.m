/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 08/01/2010.
 */


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
}

-(void) viewWillAppear:(BOOL)animated {
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_FILE()];
    self.settingsDictionary = dictionary;
    [dictionary release];

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
        case 60:    //getReady
            [self.settingsDictionary setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"menu"];
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
            return 1;   // set 2 here for the password field
            break;
        case 1:     // audio
            return 2;
            break;
        case 2:     // other stuff
            if (IS_IPAD())
                return 2;
            else
                return 1;
            break;
        default:
            DLog(@"Nope");
            break;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = NSLocalizedString(@"Main Configuration", @"");
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
    static NSString *cellIdentifier2 = @"Cell2";
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];

    UITableViewCell *cell = nil;
    EditableCellView *editableCell = nil;
    UISwitch *switchContent = nil;
    switch(section) {
        case 0:
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
            break;
        case 1:
            cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier1];
            if (nil == cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier1] autorelease];
                UISwitch *theSwitch = [[UISwitch alloc] init];
                [theSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = theSwitch;
                [theSwitch release];
            }
            
            switchContent = (UISwitch *)cell.accessoryView;
            if (row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Sound", @"");
                switchContent.on = [[self.settingsDictionary objectForKey:@"sound"] boolValue];
                switchContent.tag = 10;
            } else {
                cell.textLabel.text = NSLocalizedString(@"Music", @"");
                switchContent.on = [[self.settingsDictionary objectForKey:@"music"] boolValue];
                switchContent.tag = 20;
            }
            break;
        case 2:
            cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier2];
            if (nil == cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier2] autorelease];
                UISwitch *theSwitch = [[UISwitch alloc] init];
                [theSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = theSwitch;
                [theSwitch release];
            }
            
            switchContent = (UISwitch *)cell.accessoryView;
            if (row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Alternate Damage", @"");
                cell.detailTextLabel.text = NSLocalizedString(@"Damage popups will notify you on every single hit", @"");
                switchContent.on = [[self.settingsDictionary objectForKey:@"alternate"] boolValue];
                switchContent.tag = 30;
            } else {
                cell.textLabel.text = NSLocalizedString(@"Classic Ammo Menu", @"");
                cell.detailTextLabel.text = NSLocalizedString(@"Select which style of ammo menu you prefer",@"");
                switchContent.on = [[self.settingsDictionary objectForKey:@"menu"] boolValue];
                switchContent.tag = 60;
            }
            break;
        default:
            break;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.image = nil;

    return cell;
}

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
