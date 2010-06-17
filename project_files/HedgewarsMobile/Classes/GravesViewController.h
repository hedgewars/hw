//
//  GravesViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GravesViewController : UITableViewController {
    NSMutableDictionary *teamDictionary;
    
    NSArray *graveArray;
    NSIndexPath *lastIndexPath;
}

@property (nonatomic,retain) NSMutableDictionary *teamDictionary;
@property (nonatomic,retain) NSArray *graveArray;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
