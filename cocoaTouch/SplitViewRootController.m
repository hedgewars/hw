    //
//  SplitViewRootController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SplitViewRootController.h"
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "CommodityFunctions.h"

@implementation SplitViewRootController


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];    
    // Release any cached data, images, etc that aren't in use.
}

// load the view programmatically; we need a splitViewController that handles a MasterViewController 
// (which is just a UITableViewController) and a DetailViewController where we present options
-(void) viewDidLoad {
    detailViewController = [[DetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *detailedNavController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    [detailViewController release];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.view.frame = CGRectMake(0, 0, 1024, 768);
    
    id splitViewRootController;
    
    Class splitViewControllerClass = NSClassFromString(@"UISplitViewController");
    if (splitViewControllerClass) {
        splitViewRootController = [[splitViewControllerClass alloc] init];
        //[[splitViewRootController view] setAutoresizingMask: UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        
        [[splitViewRootController view] setFrame:CGRectMake(0, 0, 1024, 768)];
        MasterViewController *masterViewController = [[MasterViewController alloc] initWithStyle:UITableViewStylePlain];
        
        UINavigationController *mainNavController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    
        masterViewController.detailViewController = detailViewController;

        [masterViewController release];

        [splitViewRootController setViewControllers:[NSArray arrayWithObjects: mainNavController, detailedNavController, nil]];
        [mainNavController release];
        [detailedNavController release];
        
        [splitViewRootController setDelegate:detailViewController];
        [detailViewController release];

        // add view to main controller
        [self.view addSubview:[splitViewRootController view]];
    } else {
        [self.view addSubview:detailedNavController.view];
    }

    [super viewDidLoad];
}
         
-(void) viewDidUnload {
    detailViewController = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [detailViewController release];
    [super dealloc];
}

#pragma mark -
#pragma mark additional methods as we're using a UINavigationController programmatically
// see http://davidebenini.it/2009/01/03/viewwillappear-not-being-called-inside-a-uinavigationcontroller/
-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [detailViewController.navigationController viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [detailViewController.navigationController viewWillDisappear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidLoad];
    [detailViewController.navigationController viewDidAppear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidUnload];
    [detailViewController.navigationController viewDidDisappear:animated];
}


@end
