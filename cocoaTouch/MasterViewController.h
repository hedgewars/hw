//
//  MasterViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class DetailViewController;

@interface MasterViewController : UITableViewController {
    DetailViewController *detailViewController;
    NSArray *optionList;
    NSArray *controllers;
}

@property (nonatomic, retain) DetailViewController *detailViewController;
@property (nonatomic, retain) NSArray *optionList;
@property (nonatomic, retain) NSArray *controllers;

-(IBAction) dismissSplitView;

@end
