//
//  TeamSettingsViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TeamSettingsViewController.h"
#import "SingleTeamViewController.h"
#import "CommodityFunctions.h"

@implementation TeamSettingsViewController
@synthesize listOfTeams;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark View lifecycle
// add an edit button
-(void) viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit",@"from the team navigation")
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
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray: contentsOfDir copyItems:YES];
    self.listOfTeams = array;
    [array release];
    
    [self.tableView reloadData];
    NSLog(@"files: %@", self.listOfTeams);
}

// modifies the navigation bar to add the "Add" and "Done" buttons
-(void) toggleEdit:(id) sender {
    BOOL isEditing = self.tableView.editing;
    [self.tableView setEditing:!isEditing animated:YES];
    
    if (isEditing) {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Edit",@"from the team navigation")];
        [self.navigationItem.rightBarButtonItem setStyle: UIBarButtonItemStyleBordered];
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    } else {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Done",@"from the team navigation")];
        [self.navigationItem.rightBarButtonItem setStyle:UIBarButtonItemStyleDone];
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add",@"from the team navigation")
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
    [fileName release];
    
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [listOfTeams count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSUInteger row = [indexPath row]; 
    NSString *rowString = [[listOfTeams objectAtIndex:row] stringByDeletingPathExtension]; 
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

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (childController == nil) {
        childController = [[SingleTeamViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    NSInteger row = [indexPath row];
    NSString *selectedTeamFile = [listOfTeams objectAtIndex:row];
    NSLog(@"%@",selectedTeamFile);
    
    // this must be set so childController can load the correct plist
    childController.title = [selectedTeamFile stringByDeletingPathExtension];
    [childController.tableView setContentOffset:CGPointMake(0,0) animated:NO];

    [self.navigationController pushViewController:childController animated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    self.listOfTeams = nil;
    childController = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [listOfTeams release];
    [childController release];
    [super dealloc];
}


@end

