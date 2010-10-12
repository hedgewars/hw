/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 27/03/2010.
 */


#import "SplitViewRootController.h"
#import "MasterViewController.h"
#import "CommodityFunctions.h"

@implementation SplitViewRootController
@synthesize activeController;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) didReceiveMemoryWarning {
    if (self.activeController.view.superview == nil)
        self.activeController = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

// load the view programmatically; we need a splitViewController that handles a MasterViewController
// (which is just a UITableViewController) and a DetailViewController where we present options
-(void) viewDidLoad {
    CGRect rect = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(0, 0, rect.size.height, rect.size.width);

    if (self.activeController == nil) {
        MasterViewController *rightController = [[MasterViewController alloc] initWithStyle:UITableViewStyleGrouped];
        rightController.targetController = nil;
        self.activeController = rightController;
        [rightController release];
    }
    UINavigationController *rightNavController = [[UINavigationController alloc] initWithRootViewController:self.activeController];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        MasterViewController *leftController = [[MasterViewController alloc] initWithStyle:UITableViewStylePlain];
        leftController.targetController = self.activeController;
        UINavigationController *leftNavController = [[UINavigationController alloc] initWithRootViewController:leftController];
        [leftController release];

        UISplitViewController *splitViewRootController = [[UISplitViewController alloc] init];
        splitViewRootController.delegate = nil;
        splitViewRootController.view.frame = CGRectMake(0, 0, rect.size.height, rect.size.width);
        splitViewRootController.viewControllers = [NSArray arrayWithObjects: leftNavController, rightNavController, nil];
        [leftNavController release];
        [rightNavController release];

        // add view to main controller
        [self.view addSubview:splitViewRootController.view];
    } else {
        rightNavController.view.frame = CGRectMake(0, 0, rect.size.height, rect.size.width);
        [self.view addSubview:rightNavController.view];
    }

    [super viewDidLoad];
}

-(void) viewDidUnload {
    self.activeController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [self.activeController release];
    [super dealloc];
}

#pragma mark -
#pragma mark additional methods as we're using a UINavigationController programmatically
// see http://davidebenini.it/2009/01/03/viewwillappear-not-being-called-inside-a-uinavigationcontroller/
-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.activeController.navigationController viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.activeController.navigationController viewWillDisappear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidLoad];
    [self.activeController.navigationController viewDidAppear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidUnload];
    [self.activeController.navigationController viewDidDisappear:animated];
}


@end
