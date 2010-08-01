//
//  LevelViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LevelViewController : UITableViewController {
    NSDictionary *teamDictionary;

    NSArray *levelArray;
    NSArray *levelSprites;
    NSIndexPath *lastIndexPath;
}

@property (nonatomic,retain) NSDictionary *teamDictionary;
@property (nonatomic,retain) NSArray *levelArray;
@property (nonatomic,retain) NSArray *levelSprites;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
