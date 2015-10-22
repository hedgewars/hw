/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import "GeneralSettingsViewController.h"


@implementation GeneralSettingsViewController


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View Lifecycle
-(void) viewDidLoad {
    self.navigationItem.title = NSLocalizedString(@"Edit game options", nil);
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    if ([[userDefaults objectForKey:@"music"] boolValue] == NO)
        [[AudioManagerController mainManager] stopBackgroundMusic];

    [super viewWillDisappear:animated];
}

#pragma mark -
-(void) switchValueChanged:(id) sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

    switch (theSwitch.tag) {
        case 10:    //soundSwitch
            [settings setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"sound"];
            break;
        case 20:    //musicSwitch
            [settings setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"music"];
            if (theSwitch.on)
                [[AudioManagerController mainManager] playBackgroundMusic];
            else
                [[AudioManagerController mainManager] pauseBackgroundMusic];
            break;
        case 30:    //alternateSwitch
            [settings setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"alternate"];
            break;
        case 90:    //synched weapons/scheme
            [settings setObject:[NSNumber numberWithBool:theSwitch.on] forKey:@"sync_ws"];
            break;
        default:
            DLog(@"Wrong tag");
            break;
    }
}

-(void) saveTextFieldValue:(NSString *)textString withTag:(NSInteger) tagValue {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

    if (tagValue == 40)
        [settings setObject:textString forKey:@"username"];
    else
        [settings setObject:[textString MD5hash] forKey:@"password"];
}

#pragma mark -
#pragma mark TableView Methods
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger )section {
    switch (section) {
        case 0:     // user and pass
            return 1;   // set 2 here to show the password field
            break;
        case 1:     // audio
            return 2;
            break;
        case 2:     // other options
            return 2;
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
            sectionTitle = NSLocalizedString(@"Main Configuration", @"from the settings table");
            break;
        case 1:
            sectionTitle = NSLocalizedString(@"Audio Preferences", @"from the settings table");
            break;
        case 2:
            sectionTitle = NSLocalizedString(@"Other Settings", @"from the settings table");
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
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

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
                editableCell.textField.textColor = [UIColor blackColor];
            }

            if (row == 0) {
                editableCell.titleLabel.text = NSLocalizedString(@"Nickname","from the settings table");
                editableCell.textField.placeholder = NSLocalizedString(@"Insert your username (if you have one)",@"from the settings table");
                editableCell.textField.text = [settings objectForKey:@"username"];
                editableCell.textField.secureTextEntry = NO;
                editableCell.tag = 40;
            } else {
                editableCell.titleLabel.text = NSLocalizedString(@"Password","from the settings table");
                editableCell.textField.placeholder = NSLocalizedString(@"Insert your password",@"from the settings table");
                editableCell.textField.text = [settings objectForKey:@"password"];
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
                cell.textLabel.text = NSLocalizedString(@"Sound Effects", @"from the settings table");
                switchContent.on = [[settings objectForKey:@"sound"] boolValue];
                switchContent.tag = 10;
            } else {
                cell.textLabel.text = NSLocalizedString(@"Music", @"from the settings table");
                switchContent.on = [[settings objectForKey:@"music"] boolValue];
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
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            switch (row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Alternate Damage", @"from the settings table");
                    cell.detailTextLabel.text = NSLocalizedString(@"Damage popups will notify you on every single hit", @"from the settings table");
                    switchContent.on = [[settings objectForKey:@"alternate"] boolValue];
                    switchContent.tag = 30;
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Sync Schemes and Weapons", @"");
                    cell.detailTextLabel.text = NSLocalizedString(@"Choosing a Scheme will select its associated Weapon", @"from the settings table");
                    switchContent.on = [[settings objectForKey:@"sync_ws"] boolValue];
                    switchContent.tag = 90;
                    break;
                default:
                    DLog(@"Nope");
                    break;
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    [super viewDidUnload];
}

-(void) dealloc {
    [super dealloc];
}

@end
