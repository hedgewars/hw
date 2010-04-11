//
//  MasterViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "GeneralSettingsViewController.h"
#import "TeamSettingsViewController.h"
#import "CommodityFunctions.h"

@implementation MasterViewController
@synthesize detailViewController, optionList, controllers, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // the list of selectable controllers
    optionList = [[NSArray alloc] initWithObjects:NSLocalizedString(@"General",@""),
                                                  NSLocalizedString(@"Teams",@""),
                                                  NSLocalizedString(@"Weapons",@""),
                                                  NSLocalizedString(@"Schemes",@""),
                                                  nil];
    // the "Done" button on top left
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:0
                                                                                          target:self
                                                                                          action:@selector(dismissSplitView)];
    // list of allocated viewcontrollers (same in DetailViewController)
    NSMutableArray *array= [[NSMutableArray alloc] init];

    GeneralSettingsViewController *generalSettingsViewController = [[GeneralSettingsViewController alloc]
                                                                    initWithStyle:UITableViewStyleGrouped];
    generalSettingsViewController.title = NSLocalizedString(@"General",@"");
    generalSettingsViewController.navigationItem.hidesBackButton = YES;
    [array addObject:generalSettingsViewController];
    [generalSettingsViewController release];
    
    TeamSettingsViewController *teamSettingsViewController = [[TeamSettingsViewController alloc] 
                                                              initWithStyle:UITableViewStyleGrouped];
    teamSettingsViewController.title = NSLocalizedString(@"Teams",@"");
    teamSettingsViewController.navigationItem.hidesBackButton = YES;
    [array addObject:teamSettingsViewController];
    [teamSettingsViewController release];
    
    self.controllers = array;
    [array release];
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [optionList count];
}


// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.text = [optionList objectAtIndex:[indexPath row]];
    }
    
    return cell;
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
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : 0;
    
    if (newRow != oldRow) {
        [detailViewController.navigationController popToRootViewControllerAnimated:NO];
        
        UITableViewController *nextController = [self.controllers objectAtIndex:[indexPath row]];
        [detailViewController.navigationController pushViewController:nextController animated:YES];
        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [optionList release];
    [detailViewController release];
    [super dealloc];
}

-(IBAction) dismissSplitView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
}

@end

