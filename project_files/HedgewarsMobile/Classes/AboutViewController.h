//
//  AboutViewController.h
//  Hedgewars
//
//  Created by Vittorio on 01/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *tableView;
    UISegmentedControl *segmentedControl;
    NSArray *people;
}

@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (nonatomic,retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic,retain) NSArray *people;

-(IBAction) buttonPressed:(id) sender;
-(IBAction) segmentedControlChanged:(id) sender;

@end
