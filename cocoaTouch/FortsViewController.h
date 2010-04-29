//
//  FortsViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FortsViewController : UITableViewController {
    NSDictionary *teamDictionary;

    NSArray *fortArray;
//    NSArray *fortSprites;
    NSIndexPath *lastIndexPath;
}

@property (nonatomic,retain) NSDictionary * teamDictionary;
@property (nonatomic,retain) NSArray *fortArray;
//@property (nonatomic,retain) NSArray *fortSprites;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;
@end
