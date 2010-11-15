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
 * File created on 02/04/2010.
 */


#import "TeamSettingsViewController.h"
#import "CreationChamber.h"
#import "SingleTeamViewController.h"

@implementation TeamSettingsViewController
@synthesize listOfTeams;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
// add an edit button
-(void) viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit",@"")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(toggleEdit:)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
}

// load the list of teams in the teams directory
-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TEAMS_DIRECTORY() error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:contentsOfDir copyItems:YES];
    self.listOfTeams = array;
    [array release];

    [self.tableView reloadData];
}

// modifies the navigation bar to add the "Add" and "Done" buttons
-(void) toggleEdit:(id) sender {
    BOOL isEditing = self.tableView.editing;
    [self.tableView setEditing:!isEditing animated:YES];

    if (isEditing) {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Edit",@"from the team panel")];
        [self.navigationItem.rightBarButtonItem setStyle: UIBarButtonItemStyleBordered];
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    } else {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Done",@"from the team panel")];
        [self.navigationItem.rightBarButtonItem setStyle:UIBarButtonItemStyleDone];
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add",@"from the team panel")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(addTeam:)];
        self.navigationItem.leftBarButtonItem = addButton;
        [addButton release];
    }
}

// add a team file with default values and updates the table
-(void) addTeam:(id) sender {
    NSString *fileName = [[NSString alloc] initWithFormat:@"Default Team %u.plist", [self.listOfTeams count]];

    createTeamNamed([fileName stringByDeletingPathExtension]);

    [self.listOfTeams addObject:fileName];

    // order the array alphabetically, so teams will keep their position
    [self.listOfTeams sortUsingSelector:@selector(compare:)];
    [self.tableView reloadData];

    NSInteger index = [self.listOfTeams indexOfObject:fileName];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [fileName release];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfTeams count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSUInteger row = [indexPath row];
    NSString *rowString = [[self.listOfTeams objectAtIndex:row] stringByDeletingPathExtension];
    cell.textLabel.text = rowString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

// delete the row and the file
-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];

    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@",TEAMS_DIRECTORY(),[self.listOfTeams objectAtIndex:row]];
    [[NSFileManager defaultManager] removeItemAtPath:teamFile error:NULL];
    [teamFile release];

    [self.listOfTeams removeObjectAtIndex:row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (childController == nil) {
        childController = [[SingleTeamViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }

    NSInteger row = [indexPath row];
    NSString *selectedTeamFile = [listOfTeams objectAtIndex:row];

    // this must be set so childController can load the correct plist
    childController.teamName = [selectedTeamFile stringByDeletingPathExtension];
    [childController.tableView setContentOffset:CGPointMake(0,0) animated:NO];

    [self.navigationController pushViewController:childController animated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
    if (childController.view.superview == nil )
        childController = nil;
}

-(void) viewDidUnload {
    self.listOfTeams = nil;
    childController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [self.listOfTeams release];
    [childController release];
    [super dealloc];
}


@end

