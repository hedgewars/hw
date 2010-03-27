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
    detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    masterViewController = [[MasterViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    // set attributes
    masterViewController.detailViewController = detailViewController;
    splitViewController.viewControllers = [NSArray arrayWithObjects:navigationController, detailViewController, nil];
	splitViewController.delegate = detailViewController;
    
    // add view to main controller
    [self.view addSubview:splitViewController.view];
     
    [super viewDidLoad];
}

-(void) dealloc {
    [detailViewController release];
    [masterViewController release];
    [splitViewController release];
    [super dealloc];
}


@end
