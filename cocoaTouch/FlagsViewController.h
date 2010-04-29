//
//  FlagsViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FlagsViewController : UITableViewController {
    NSDictionary *teamDictionary;

    NSArray *flagArray;    
    NSIndexPath *lastIndexPath;
}

@property (nonatomic,retain) NSDictionary * teamDictionary;
@property (nonatomic,retain) NSArray *flagArray;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
