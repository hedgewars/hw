//
//  HogHatViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GravesViewController : UITableViewController {
    NSDictionary *teamDictionary;
    
    NSArray *graveArray;
    NSArray *graveSprites;
    NSIndexPath *lastIndexPath;
}

@property (nonatomic,retain) NSDictionary *teamDictionary;
@property (nonatomic,retain) NSArray *graveArray;
@property (nonatomic,retain) NSArray *graveSprites;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
