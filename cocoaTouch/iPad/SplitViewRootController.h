//
//  SplitViewRootController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MasterViewController;
@class DetailViewController;
@interface SplitViewRootController : UIViewController {
    UISplitViewController *splitViewController;
    MasterViewController *masterViewController;
    DetailViewController *detailViewController;
}

@property (nonatomic,retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic,retain) IBOutlet MasterViewController *masterViewController;
@property (nonatomic,retain) IBOutlet DetailViewController *detailViewController;
@end
