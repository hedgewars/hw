//
//  TeamConfigViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 20/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TeamConfigViewController : UITableViewController {
    NSMutableArray *listOfTeams;
    NSMutableArray *listOfSelectedTeams;
    NSIndexPath *lastIndexPath;
}

@property (nonatomic, retain) NSMutableArray *listOfTeams;
@property (nonatomic, retain) NSMutableArray *listOfSelectedTeams;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
