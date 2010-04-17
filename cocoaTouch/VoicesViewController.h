//
//  VoicesViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VoicesViewController : UITableViewController {
    NSMutableDictionary *teamDictionary;
    
    NSArray *voiceArray;
    NSIndexPath *lastIndexPath;

    int voiceBeingPlayed;
}

@property (nonatomic,retain) NSMutableDictionary *teamDictionary;
@property (nonatomic,retain) NSArray *voiceArray;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
