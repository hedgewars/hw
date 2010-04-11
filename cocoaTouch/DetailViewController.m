    //
//  DetailViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "SDL_uikitappdelegate.h"
#import "TeamSettingsViewController.h"
#import "GeneralSettingsViewController.h"
#import "CommodityFunctions.h"

@implementation DetailViewController
@synthesize popoverController, controllers;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Settings",@"");

    // allocate controllers and store them into the array
    NSMutableArray *array= [[NSMutableArray alloc] init];

    GeneralSettingsViewController *generalSettingsViewController = [[GeneralSettingsViewController alloc]
                                                                    initWithStyle:UITableViewStyleGrouped];
    generalSettingsViewController.title = NSLocalizedString(@"General",@"");
    [array addObject:generalSettingsViewController];
    [generalSettingsViewController release];
    
    TeamSettingsViewController *teamSettingsViewController = [[TeamSettingsViewController alloc] 
                                                              initWithStyle:UITableViewStyleGrouped];
    teamSettingsViewController.title = NSLocalizedString(@"Teams",@"");
    [array addObject:teamSettingsViewController];
    [teamSettingsViewController release];
    
    self.controllers = array;
    [array release];
    
    // on ipad make the general setting the first view, on iphone add the "Done" button on top left
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UITableViewController *nextController = [self.controllers objectAtIndex:0];
        nextController.navigationItem.hidesBackButton = YES;
        [self.navigationController pushViewController:nextController animated:NO];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismissSplitView)];
    }

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.controllers = nil;
    self.popoverController = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    [controllers release];
    [popoverController release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [controllers count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger row = [indexPath row];
    UITableViewController *controller = [controllers objectAtIndex:row];
    
    cell.textLabel.text = controller.title;
    cell.imageView.image = [UIImage imageNamed:@"Icon.png"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    UITableViewController *nextController = [self.controllers objectAtIndex:row];
    [self.navigationController pushViewController:nextController animated:YES];
}

/*
#pragma mark -
#pragma mark Managing the popover controller
// When setting the detail item, update the view and dismiss the popover controller if it's showing.
-(void) setDetailItem:(id) newDetailItem {
    if (detailItem != newDetailItem) {
        [detailItem release];
        detailItem = [newDetailItem retain];
        
        // Update the view.
       // navigationBar.topItem.title = (NSString*) detailItem;

		//test.text=(NSString*) detailItem;
    }

  //  if (popoverController != nil) {
  //      [popoverController dismissPopoverAnimated:YES];
  //  }        
}
*/

#pragma mark -
#pragma mark Split view support
#ifdef __IPHONE_3_2
-(void) splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    barButtonItem.title = @"Master List";
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
-(void) splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:nil animated:YES];
    self.popoverController = nil;
}
#endif

-(IBAction) dismissSplitView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
}

@end
