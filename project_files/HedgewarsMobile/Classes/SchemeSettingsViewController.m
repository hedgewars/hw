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


#import "SchemeSettingsViewController.h"
#import "SingleSchemeViewController.h"


@implementation SchemeSettingsViewController
@synthesize listOfSchemes;

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

    self.navigationItem.title = NSLocalizedString(@"List of schemes", nil);
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];

    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:SCHEMES_DIRECTORY() error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:contentsOfDir copyItems:YES];
    self.listOfSchemes = array;
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
                                                                     action:@selector(addScheme:)];
        self.navigationItem.leftBarButtonItem = addButton;
        [addButton release];
    }
}

-(void) addScheme:(id) sender {
    NSString *fileName = [[NSString alloc] initWithFormat:@"Scheme %u.plist", [self.listOfSchemes count]];

    [CreationChamber createSchemeNamed:[fileName stringByDeletingPathExtension]];

    [self.listOfSchemes addObject:fileName];

    // order the array alphabetically, so schemes will keep their position
    [self.listOfSchemes sortUsingSelector:@selector(compare:)];
    [self.tableView reloadData];

    NSInteger index = [self.listOfSchemes indexOfObject:fileName];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [fileName release];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfSchemes count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSUInteger row = [indexPath row];
    NSString *rowString = [[self.listOfSchemes objectAtIndex:row] stringByDeletingPathExtension];
    cell.textLabel.text = rowString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

// delete the row and the file
-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];

    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@",SCHEMES_DIRECTORY(),[self.listOfSchemes objectAtIndex:row]];
    [[NSFileManager defaultManager] removeItemAtPath:schemeFile error:NULL];
    [schemeFile release];

    [self.listOfSchemes removeObjectAtIndex:row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SingleSchemeViewController *singleSchemeViewController = [[SingleSchemeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    NSInteger row = [indexPath row];
    NSString *selectedSchemeFile = [self.listOfSchemes objectAtIndex:row];

    // this must be set so childController can load the correct plist
    singleSchemeViewController.schemeName = [selectedSchemeFile stringByDeletingPathExtension];
    [singleSchemeViewController.tableView setContentOffset:CGPointMake(0,0) animated:NO];

    [self.navigationController pushViewController:singleSchemeViewController animated:YES];
    [singleSchemeViewController release];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    MSG_MEMCLEAN();
}

-(void) viewDidUnload
{
    self.listOfSchemes = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc
{
    releaseAndNil(listOfSchemes);
    [super dealloc];
}


@end

