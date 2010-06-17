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
    if (detailViewController.view.superview == nil)
        detailViewController = nil;
    MSG_MEMCLEAN();
}

// load the view programmatically; we need a splitViewController that handles a MasterViewController 
// (which is just a UITableViewController) and a DetailViewController where we present options
-(void) viewDidLoad {
    detailViewController = [[DetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *detailedNavController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    [detailViewController release];

    CGRect rect = [[UIScreen mainScreen] bounds];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.view.frame = CGRectMake(0, 0, rect.size.height, rect.size.width);
        
    Class splitViewControllerClass = NSClassFromString(@"UISplitViewController");
    if (splitViewControllerClass) {
#if __IPHONE_3_2
        UISplitViewController *splitViewRootController = [[UISplitViewController alloc] init];
        //splitViewRootController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;        
        splitViewRootController.view.frame = CGRectMake(0, 0, rect.size.height, rect.size.width);
        
        MasterViewController *masterViewController = [[MasterViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *mainNavController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
        [masterViewController release];

        splitViewRootController.delegate = detailViewController;
        masterViewController.detailViewController = detailViewController;        
        splitViewRootController.viewControllers = [NSArray arrayWithObjects: mainNavController, detailedNavController, nil];
        [mainNavController release];
        [detailedNavController release];
        
        // add view to main controller
        [self.view addSubview:splitViewRootController.view];
#endif
    } else {
        [self.view addSubview:detailedNavController.view];
    }

    [super viewDidLoad];
}
         
-(void) viewDidUnload {
    detailViewController = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}

-(void) dealloc {
    [detailViewController release];
    [super dealloc];
}
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [detailViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
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
