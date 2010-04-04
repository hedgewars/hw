//
//  SingleTeamViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HogHatViewController;
@interface SingleTeamViewController : UITableViewController {
    NSArray *hogsList;
    NSArray *secondaryItems;
    NSString *teamName;
    
    HogHatViewController *hogChildController;
}

@property (nonatomic,retain) NSArray *hogsList;
@property (nonatomic,retain) NSArray *secondaryItems;
@property (nonatomic,retain) NSString *teamName;
@end
