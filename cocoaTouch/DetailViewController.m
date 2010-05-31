    //
//  DetailViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "SDL_uikitappdelegate.h"
#import "GeneralSettingsViewController.h"
#import "TeamSettingsViewController.h"
#import "WeaponSettingsViewController.h"
#import "SchemeSettingsViewController.h"
#import "CommodityFunctions.h"

@implementation DetailViewController
@synthesize popoverController, controllerNames;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}

-(void) viewDidLoad {
    self.title = NSLocalizedString(@"Settings",@"");

    // allocate controllers and store them into the array
    NSArray *array= [[NSArray alloc] initWithObjects:NSLocalizedString(@"General",@""), 
                                                     NSLocalizedString(@"Teams",@""),
                                                     NSLocalizedString(@"Weapons",@""),
                                                     NSLocalizedString(@"Schemes",@""),
                                                     nil];
    self.controllerNames = array;
    [array release];
    
    // on ipad make the general setting the first view, on iphone add the "Done" button on top left
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(112, 112, 480, 320)];
        label.text = @"Press the buttons on the left";
        label.font = [UIFont systemFontOfSize:20];
        label.textAlignment = UITextAlignmentCenter;
        [self.view addSubview:label];
        [label release];
        
        //[self.navigationController pushViewController:nextController animated:NO];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(dismissSplitView)];
    }

    [super viewDidLoad];
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    // don't display 
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 0;
    else
        return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [controllerNames count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger row = [indexPath row];
    
    cell.textLabel.text = [controllerNames objectAtIndex:row];
    cell.imageView.image = [UIImage imageNamed:@"Icon.png"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    UIViewController *nextController = nil;
    
    switch (row) {
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
    
    nextController.title = [controllerNames objectAtIndex:row];
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
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
-(void) splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.popoverController = nil;
}
#endif

-(IBAction) dismissSplitView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
}


-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
    generalSettingsViewController = nil;
    teamSettingsViewController = nil;
    weaponSettingsViewController = nil;
    schemeSettingsViewController = nil;
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    self.controllerNames = nil;
    self.popoverController = nil;
    generalSettingsViewController = nil;
    teamSettingsViewController = nil;
    weaponSettingsViewController = nil;
    schemeSettingsViewController = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [controllerNames release];
    [popoverController release];
    [generalSettingsViewController release];
    [teamSettingsViewController release];
    [weaponSettingsViewController release];
    [schemeSettingsViewController release];
    [super dealloc];
}
@end
