//
//  SplitViewRootController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MasterViewController;

@interface SplitViewRootController: UIViewController {
    MasterViewController *activeController;
}

@property (nonatomic,retain) MasterViewController *activeController;

@end
