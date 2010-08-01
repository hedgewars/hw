//
//  SingleSchemeViewController.h
//  Hedgewars
//
//  Created by Vittorio on 23/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditableCellView.h"

@interface SingleSchemeViewController : UITableViewController <EditableCellViewDelegate> {
    NSString *schemeName;
    NSMutableArray *schemeArray;
    NSArray *basicSettingList;
    NSArray *gameModifierArray;
}

@property (nonatomic, retain) NSString *schemeName;
@property (nonatomic, retain) NSMutableArray *schemeArray;
@property (nonatomic, retain) NSArray *basicSettingList;
@property (nonatomic, retain) NSArray *gameModifierArray;

@end
