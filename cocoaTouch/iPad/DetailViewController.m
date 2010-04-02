    //
//  DetailViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "TeamSettingsViewController.h"

@implementation DetailViewController
@synthesize popoverController, detailItem, controllers;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    self.title =@"First";
    NSMutableArray *array= [[NSMutableArray alloc] init];

    TeamSettingsViewController *teamSettingsViewController = [[TeamSettingsViewController alloc] 
                                                              initWithStyle:UITableViewStyleGrouped];
    teamSettingsViewController.title =NSLocalizedString(@"Teams",@"");
    [array addObject:teamSettingsViewController];
    [teamSettingsViewController release];
    
    self.controllers = array;
    [array release];
        
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
    self.detailItem = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    [controllers release];
    [popoverController release];
    [detailItem release];
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

    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark -
#pragma mark Split view support
-(void) splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
    barButtonItem.title = @"Master List";
  //  [navigationBar.topItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
-(void) splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
  //  [navigationBar.topItem setLeftBarButtonItem:nil animated:YES];
    self.popoverController = nil;
}

#pragma mark -
#pragma mark Rotation support
// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
