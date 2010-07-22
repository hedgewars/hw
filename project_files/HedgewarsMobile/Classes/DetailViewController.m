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
@synthesize controllerNames,popoverController;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    self.view.frame = CGRectMake(0, 0, 1024, 1024);
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

-(IBAction) dismissSplitView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
}

#pragma mark -
#pragma mark splitview support
-(void) splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController {
    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }
}

// Called when the master view controller is about to be hidden
-(void) splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController 
            withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {

  /*  barButtonItem.title = @"Master View";
    UIToolbar *toolbar = self.parentViewController.navigationController.toolbar;
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    [toolbar setItems:items animated:YES];

    [items release];

    self.popoverController = pc;*/
    barButtonItem.title = aViewController.title;
    self.navigationItem.rightBarButtonItem = barButtonItem;
}

// Called when the master view controller is about to appear
-(void) splitViewController: (UISplitViewController*)svc  willShowViewController:(UIViewController *)aViewController 
            invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    /*UIToolbar *toolbar = self.parentViewController.navigationController.toolbar;

    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items removeObjectAtIndex:0];

    [toolbar setItems:items animated:YES];

    [items release];

    self.popoverController = nil;*/
        self.navigationItem.rightBarButtonItem = nil;

}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
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
    self.controllerNames = nil;
    generalSettingsViewController = nil;
    teamSettingsViewController = nil;
    weaponSettingsViewController = nil;
    schemeSettingsViewController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [controllerNames release];
    [generalSettingsViewController release];
    [teamSettingsViewController release];
    [weaponSettingsViewController release];
    [schemeSettingsViewController release];
    [super dealloc];
}
@end
