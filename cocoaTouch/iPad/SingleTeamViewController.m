//
//  SingleTeamViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SingleTeamViewController.h"
#import "HogHatViewController.h"

@implementation SingleTeamViewController
@synthesize hogsList, secondaryItems, teamName;


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
   
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:
                             NSLocalizedString(@"Color",@""),
                             NSLocalizedString(@"Grave",@""),
                             NSLocalizedString(@"Voice",@""),
                             NSLocalizedString(@"Fort",@""),
                             NSLocalizedString(@"Flag",@""),
                             NSLocalizedString(@"Level",@""),nil];
    self.secondaryItems = array;
    [array release];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@Teams/%@.plist",[paths objectAtIndex:0],self.teamName];
    NSDictionary *teamDict = [[NSDictionary alloc] initWithContentsOfFile:teamFile];
    [teamFile release];
    
    self.hogsList = [teamDict objectForKey:@"hedgehogs"];
    self.teamName = [teamDict objectForKey:@"teamname"];
    [teamDict release];
    self.title = teamName;
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows;
    switch (section) {
        case 0:
            rows = 1;
            break;
        case 1:
            rows = 8;
            break;
        case 2:
            rows = 6;
            break;
        default:
            break;
    }
    return rows;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger row = [indexPath row];
    switch ([indexPath section]) {
        case 0:
            cell.textLabel.text = teamName;
            break;
        case 1:
            cell.textLabel.text = [[self.hogsList objectAtIndex:row] objectForKey:@"hogname"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 2:
            cell.textLabel.text = [self.secondaryItems objectAtIndex:row];
            break;
        default:
            break;
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


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

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (1 == [indexPath section]) {
        if (nil == hogChildController) {
            hogChildController = [[HogHatViewController alloc] initWithStyle:UITableViewStyleGrouped];
        }
    
        hogChildController.hog = [hogsList objectAtIndex:[indexPath row]];
        //NSLog(@"%@",hogChildController.hog);
        [self.navigationController pushViewController:hogChildController animated:YES];
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
    self.hogsList = nil;
    self.secondaryItems = nil;
    self.teamName = nil;
}


-(void) dealloc {
    [secondaryItems release];
    [hogsList release];
    [teamName release];
    [super dealloc];
}


@end

