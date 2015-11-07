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


#import "WeaponSettingsViewController.h"
#import "SingleWeaponViewController.h"


@implementation WeaponSettingsViewController
@synthesize listOfWeapons;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit",@"")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(toggleEdit:)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];

    self.navigationItem.title = NSLocalizedString(@"List of weapons", nil);
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];

    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:WEAPONS_DIRECTORY() error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:contentsOfDir copyItems:YES];
    self.listOfWeapons = array;
    [array release];

    [self.tableView reloadData];
}

// modifies the navigation bar to add the "Add" and "Done" buttons
-(void) toggleEdit:(id) sender {
    BOOL isEditing = self.tableView.editing;
    [self.tableView setEditing:!isEditing animated:YES];

    if (isEditing) {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Edit",@"from the scheme panel")];
        [self.navigationItem.rightBarButtonItem setStyle: UIBarButtonItemStyleBordered];
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    } else {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Done",@"from the scheme panel")];
        [self.navigationItem.rightBarButtonItem setStyle:UIBarButtonItemStyleDone];
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add",@"from the scheme panel")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(addWeapon:)];
        self.navigationItem.leftBarButtonItem = addButton;
        [addButton release];
    }
}

-(void) addWeapon:(id) sender {
    NSString *fileName = [[NSString alloc] initWithFormat:@"Weapon %u.plist", [self.listOfWeapons count]];

    [CreationChamber createWeaponNamed:[fileName stringByDeletingPathExtension]];

    [self.listOfWeapons addObject:fileName];

    // order the array alphabetically, so schemes will keep their position
    [self.listOfWeapons sortUsingSelector:@selector(compare:)];
    [self.tableView reloadData];

    NSInteger index = [self.listOfWeapons indexOfObject:fileName];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [fileName release];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfWeapons count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSUInteger row = [indexPath row];
    NSString *rowString = [[self.listOfWeapons objectAtIndex:row] stringByDeletingPathExtension];
    cell.textLabel.text = rowString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

// delete the row and the file
-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];

    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@",WEAPONS_DIRECTORY(),[self.listOfWeapons objectAtIndex:row]];
    [[NSFileManager defaultManager] removeItemAtPath:schemeFile error:NULL];
    [schemeFile release];

    [self.listOfWeapons removeObjectAtIndex:row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SingleWeaponViewController *singleWeaponViewController = [[SingleWeaponViewController alloc] initWithStyle:UITableViewStyleGrouped];

    NSInteger row = [indexPath row];
    NSString *selectedWeaponFile = [self.listOfWeapons objectAtIndex:row];

    // this must be set so childController can load the correct plist
    singleWeaponViewController.weaponName = [selectedWeaponFile stringByDeletingPathExtension];
    [singleWeaponViewController.tableView setContentOffset:CGPointMake(0,0) animated:NO];

    [self.navigationController pushViewController:singleWeaponViewController animated:YES];
    [singleWeaponViewController release];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload
{
    self.listOfWeapons = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc
{
    releaseAndNil(listOfWeapons);
    [super dealloc];
}


@end

