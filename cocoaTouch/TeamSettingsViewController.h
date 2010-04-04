//
//  TeamSettingsViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SingleTeamViewController;

@interface TeamSettingsViewController : UITableViewController {
    NSArray	*list;
    SingleTeamViewController *childController;
}
@property (nonatomic, retain) NSArray *list;

@end
