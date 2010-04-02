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

@implementation SplitViewRootController
@synthesize splitViewController, masterViewController, detailViewController;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];    
    // Release any cached data, images, etc that aren't in use.
}

// load the view programmatically; we need a splitViewController that handles a MasterViewController 
// (which is just a UITableViewController) and a DetailViewController where we present options
-(void) viewDidLoad {
    // init every possible controller
    splitViewController = [[UISplitViewController alloc] init];
    masterViewController = [[MasterViewController alloc] initWithStyle:UITableViewStylePlain];
    detailViewController = [[DetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    UINavigationController *mainNavController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    UINavigationController *detailedNavController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    
    // set attributes
    masterViewController.detailViewController = detailViewController;
    splitViewController.viewControllers = [NSArray arrayWithObjects: mainNavController, detailedNavController, nil];
    [mainNavController release];
    [detailedNavController release];
	
    splitViewController.delegate = detailViewController;
    
    // add view to main controller
    [self.view addSubview:splitViewController.view];
    [detailViewController release];
    [masterViewController release];

    [super viewDidLoad];
}

-(void) dealloc {
    [detailViewController release];
    [masterViewController release];
    [splitViewController release];
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
