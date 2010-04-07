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
@synthesize detailViewController;


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
    self.detailViewController = [[DetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
     [detailViewController release];
           NSLog(@"%d", [detailViewController retainCount]);

    UINavigationController *detailedNavController = [[UINavigationController alloc] initWithRootViewController:self.detailViewController];
            NSLog(@"%d", [detailViewController retainCount]);

    [detailViewController release];
            NSLog(@"%d", [detailViewController retainCount]);

    id splitViewRootController;
    
    Class splitViewControllerClass = NSClassFromString(@"UISplitViewController");
    if (splitViewControllerClass) {
        splitViewRootController = [[splitViewControllerClass alloc] init];
        CGRect screensize = [[UIScreen mainScreen] bounds];
        [[splitViewRootController view] setFrame:CGRectMake(0, 0, screensize.size.height, screensize.size.width)];
        MasterViewController *masterViewController = [[MasterViewController alloc] initWithStyle:UITableViewStylePlain];
        
        UINavigationController *mainNavController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    
        masterViewController.detailViewController = self.detailViewController;
                NSLog(@"%d", [detailViewController retainCount]);

        [masterViewController release];

        [splitViewRootController setViewControllers:[NSArray arrayWithObjects: mainNavController, detailedNavController, nil]];
        [mainNavController release];
        [detailedNavController release];
        
        [splitViewRootController setDelegate: self.detailViewController];
        [detailViewController release];
                NSLog(@"%d", [detailViewController retainCount]);

        // add view to main controller
        [self.view addSubview:[splitViewRootController view]];
        //[splitViewRootController release];

    } else {
        [self.view addSubview:detailedNavController.view];
    }


    [super viewDidLoad];
}
         
-(void) viewDidUnload {
    [super viewDidUnload];
    self.detailViewController = nil;
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
