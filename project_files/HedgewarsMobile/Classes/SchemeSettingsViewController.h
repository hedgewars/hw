//
//  SchemeSettingsViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 19/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SingleSchemeViewController;

@interface SchemeSettingsViewController : UITableViewController {
    NSMutableArray *listOfSchemes;
    SingleSchemeViewController *childController;
}

@property (nonatomic, retain) NSMutableArray *listOfSchemes;

@end
