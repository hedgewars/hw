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
    NSMutableDictionary *teamDictionary;
    NSArray *hatArray;
    
    NSArray *secondaryItems;
    NSArray *secondaryControllers;
    BOOL isWriteNeeded;
    
    HogHatViewController *hogChildController;
}

@property (nonatomic,retain) NSMutableDictionary *teamDictionary;
@property (nonatomic,retain) NSArray *hatArray;
@property (nonatomic,retain) NSArray *secondaryItems;
@property (nonatomic,retain) NSArray *secondaryControllers;
@end
