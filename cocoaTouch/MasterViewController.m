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
#import "WeaponSettingsViewController.h"
#import "SchemeSettingsViewController.h"
#import "CommodityFunctions.h"

@implementation MasterViewController
@synthesize detailViewController, controllerNames, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];
    
    // the list of selectable controllers
    controllerNames = [[NSArray alloc] initWithObjects:NSLocalizedString(@"General",@""),
                                                       NSLocalizedString(@"Teams",@""),
                                                       NSLocalizedString(@"Weapons",@""),
                                                       NSLocalizedString(@"Schemes",@""),
                                                       nil];
    // the "Done" button on top left
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(dismissSplitView)];
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [controllerNames count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.text = [controllerNames objectAtIndex:[indexPath row]];
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    UIViewController *nextController = nil;
    
    if (newRow != oldRow) {
        [self.tableView deselectRowAtIndexPath:lastIndexPath animated:YES];
        [detailViewController.navigationController popToRootViewControllerAnimated:NO];
        
        switch (newRow) {
            case 0:
                if (nil == generalSettingsViewController)
                    generalSettingsViewController = [[GeneralSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = generalSettingsViewController;
                break;
            case 1:
                if (nil == teamSettingsViewController)
                    teamSettingsViewController = [[TeamSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = teamSettingsViewController;
                break;
            case 2:
                if (nil == weaponSettingsViewController)
                    weaponSettingsViewController = [[WeaponSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = weaponSettingsViewController;
                break;
            case 3:
                if (nil == schemeSettingsViewController)
                    schemeSettingsViewController = [[SchemeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = schemeSettingsViewController;
                break;
        }
        
        nextController.navigationItem.hidesBackButton = YES;
        nextController.title = [controllerNames objectAtIndex:newRow];
        [detailViewController.navigationController pushViewController:nextController animated:NO];
        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.    
    if (generalSettingsViewController.view.superview == nil)
        generalSettingsViewController = nil;
    if (teamSettingsViewController.view.superview == nil)
        teamSettingsViewController = nil;
    if (weaponSettingsViewController.view.superview == nil)
        weaponSettingsViewController = nil;
    if (schemeSettingsViewController.view.superview == nil)
        schemeSettingsViewController = nil;
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    self.detailViewController = nil;
    self.controllerNames = nil;
    self.lastIndexPath = nil;
    generalSettingsViewController = nil;
    teamSettingsViewController = nil;
    weaponSettingsViewController = nil;
    schemeSettingsViewController = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}

-(void) dealloc {
    [controllerNames release];
    [detailViewController release];
    [lastIndexPath release];
    [generalSettingsViewController release];
    [teamSettingsViewController release];
    [weaponSettingsViewController release];
    [schemeSettingsViewController release];
    [super dealloc];
}

-(IBAction) dismissSplitView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
}

@end

