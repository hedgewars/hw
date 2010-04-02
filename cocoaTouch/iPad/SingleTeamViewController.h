//
//  SingleTeamViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SingleTeamViewController : UITableViewController {
    NSArray *hogsList;
    NSArray *secondaryItems;
}

@property (nonatomic,retain) NSArray *hogsList;
@property (nonatomic,retain) NSArray *secondaryItems;
@end
