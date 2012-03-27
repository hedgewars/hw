/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 */


#import "SettingsContainerViewController.h"
#import "SettingsBaseViewController.h"
#import "MGSplitViewController.h"


@implementation SettingsContainerViewController
@synthesize baseController, splitViewRootController;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) viewDidLoad {
    CGRect screenRect = [[UIScreen mainScreen] safeBounds];
    self.view.frame = screenRect;

    if (IS_IPAD()) {
        // the contents on the right of the splitview, setting targetController to nil to avoid creating the table
        SettingsBaseViewController *rightController = [[SettingsBaseViewController alloc] init];
        rightController.targetController = nil;
        UINavigationController *rightNavController = [[UINavigationController alloc] initWithRootViewController:rightController];
        [rightController release];

        // the contens on the left of the splitview, setting targetController that will receive push/pop actions
        SettingsBaseViewController *leftController = [[SettingsBaseViewController alloc] init];
        leftController.targetController = rightNavController.topViewController;
        UINavigationController *leftNavController = [[UINavigationController alloc] initWithRootViewController:leftController];
        [leftController release];

        self.splitViewRootController = [[MGSplitViewController alloc] init];
        self.splitViewRootController.delegate = nil;
        self.splitViewRootController.view.frame = screenRect;
        self.splitViewRootController.viewControllers = [NSArray arrayWithObjects: leftNavController, rightNavController, nil];
        self.splitViewRootController.showsMasterInPortrait = YES;
        [leftNavController release];
        [rightNavController release];

        // add view to main controller
        [self.view addSubview:self.splitViewRootController.view];
    } else {
        if (nil == self.baseController) {
            SettingsBaseViewController *sbvc = [[SettingsBaseViewController alloc] init];
            self.baseController = sbvc;
            [sbvc release];
        }
        self.baseController.targetController = nil;
        self.baseController.view.frame = screenRect;

        [self.view addSubview:self.baseController.view];
    }

    [super viewDidLoad];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    if (self.baseController.view.superview == nil)
        self.baseController = nil;
    if (self.splitViewRootController.view.superview == nil)
        self.splitViewRootController = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.baseController = nil;
    self.splitViewRootController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(baseController);
    releaseAndNil(splitViewRootController);
    [super dealloc];
}


#pragma mark -
#pragma mark view event management propagation
// every time we add a uiviewcontroller programmatically we need to take care of propgating such messages
// see http://davidebenini.it/2009/01/03/viewwillappear-not-being-called-inside-a-uinavigationcontroller/
-(void) viewWillAppear:(BOOL)animated {
    [self.splitViewRootController.detailViewController viewWillAppear:animated];
    [self.baseController viewWillAppear:animated];
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [self.splitViewRootController.detailViewController viewWillDisappear:animated];
    [self.baseController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [self.splitViewRootController.detailViewController viewDidAppear:animated];
    [self.baseController viewDidAppear:animated];
    [super viewDidAppear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [self.splitViewRootController.detailViewController viewDidDisappear:animated];
    [self.baseController viewDidDisappear:animated];
    [super viewDidDisappear:animated];
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.splitViewRootController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.baseController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.splitViewRootController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.baseController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.splitViewRootController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.baseController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

@end
