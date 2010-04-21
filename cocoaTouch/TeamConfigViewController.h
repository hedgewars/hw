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
}

@property (nonatomic, retain) NSMutableArray *listOfTeams;

@end
