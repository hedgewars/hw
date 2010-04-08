//
//  TeamSettingsViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TeamSettingsViewController.h"
#import "SingleTeamViewController.h"

@implementation TeamSettingsViewController
@synthesize listOfTeams;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit",@"from the team navigation")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(toggleEdit:)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *teamsDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/Teams/"];
    
    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:teamsDirectory error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray: contentsOfDir copyItems:YES];
    self.listOfTeams = array;
    [array release];
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
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *teamsDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/Teams/"];
    [[NSFileManager defaultManager] createDirectoryAtPath:teamsDirectory 
                              withIntermediateDirectories:NO 
                                               attributes:nil 
                                                    error:NULL];
    
    NSMutableArray *hedgehogs = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 8; i++) {
        NSString *hogName = [[NSString alloc] initWithFormat:@"hedgehog %d",i];
        NSDictionary *hog = [[NSDictionary alloc] initWithObjectsAndKeys:@"100",@"health",@"0",@"level",
                             hogName,@"hogname",@"NoHat",@"hat",nil];
        [hogName release];
        [hedgehogs addObject:hog];
        [hog release];
    }
    
    NSString *fileName = [[NSString alloc] initWithFormat:@"Default Team %u.plist", [self.listOfTeams count]];

    NSDictionary *defaultTeam = [[NSDictionary alloc] initWithObjectsAndKeys:@"4421353",@"color",@"0",@"hash",
                                 [fileName stringByDeletingPathExtension],@"teamname",@"Statue",@"grave",@"Plane",@"fort",
                                 @"Default",@"voicepack",@"hedgewars",@"flag",hedgehogs,@"hedgehogs",nil];
    [hedgehogs release];
    
    NSString *defaultTeamFile = [[NSString alloc] initWithFormat:@"%@/%@",teamsDirectory, fileName];
    [defaultTeam writeToFile:defaultTeamFile atomically:YES];
    [defaultTeamFile release];    
    [defaultTeam release];
    
    [self.listOfTeams addObject:fileName];
    [fileName release];
    
    [self.tableView reloadData];
    
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
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
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/Teams/%@",[paths objectAtIndex:0],[self.listOfTeams objectAtIndex:row]];

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

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (childController == nil) {
        childController = [[SingleTeamViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    NSInteger row = [indexPath row];
    NSString *selectedTeamFile = [listOfTeams objectAtIndex:row];
    NSLog(@"%@",selectedTeamFile);
    
        // load data about the team and extract info
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/Teams/%@",[paths objectAtIndex:0],selectedTeamFile];
    NSMutableDictionary *teamDict = [[NSMutableDictionary alloc] initWithContentsOfFile:teamFile];
    [teamFile release];
    childController.teamDictionary = teamDict;
    [teamDict release];
    
    // this must be set so childController can load the correct plist
    //childController.title = [[listOfTeams objectAtIndex:row] stringByDeletingPathExtension];
    [self.navigationController pushViewController:childController animated:YES];
}

/*
-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Hey, do you see the disclosure button?" 
                                                    message:@"If you're trying to drill down, touch that instead" 
                                                   delegate:nil
                                          cancelButtonTitle:@"Won't happen again"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}
*/

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    self.listOfTeams = nil;
}

-(void) dealloc {
    [listOfTeams release];
    [childController release];
    [super dealloc];
}


@end

