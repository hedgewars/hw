//
//  HogHatViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HogHatViewController : UITableViewController {
    NSArray *hatList;
    NSArray *hatSprites;
    NSDictionary *hog;
}

@property (nonatomic,retain) NSArray *hatList;
@property (nonatomic,retain) NSArray *hatSprites;
@property (nonatomic,retain) NSDictionary *hog;

@end
