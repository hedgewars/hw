//
//  DetailViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
                    UINavigationBarDelegate, UIPopoverControllerDelegate, UISplitViewControllerDelegate>  {
    UIPopoverController *popoverController;
    UINavigationBar *navigationBar;
    NSArray *optionList;
	UITableView * table;

    id detailItem;
    UILabel *test;
}

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UILabel *test;
@property (nonatomic, retain) id detailItem;
@property (nonatomic, retain) NSArray *optionList;
@property (nonatomic, retain) IBOutlet UITableView *table;

-(IBAction) dismissSplitView;

@end
