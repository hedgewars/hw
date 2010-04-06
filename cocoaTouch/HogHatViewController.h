//
//  HogHatViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HogHatViewController : UITableViewController {
    NSDictionary *teamDictionary;
    NSInteger selectedHog;
    
    NSArray *hatArray;
    NSArray *hatSprites;
    NSIndexPath *lastIndexPath;
}

@property (nonatomic,retain) NSDictionary * teamDictionary;
@property (nonatomic) NSInteger selectedHog;
@property (nonatomic,retain) NSArray *hatArray;
@property (nonatomic,retain) NSArray *hatSprites;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
