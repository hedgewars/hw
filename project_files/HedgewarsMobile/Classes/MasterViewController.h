//
//  MasterViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class DetailViewController;
@class GeneralSettingsViewController;
@class TeamSettingsViewController;
@class WeaponSettingsViewController;
@class SchemeSettingsViewController;

@interface MasterViewController : UITableViewController {
    DetailViewController *detailViewController;
    NSArray *controllerNames;
    NSIndexPath *lastIndexPath;
    GeneralSettingsViewController *generalSettingsViewController;
    TeamSettingsViewController *teamSettingsViewController;
    WeaponSettingsViewController *weaponSettingsViewController;
    SchemeSettingsViewController *schemeSettingsViewController;
}

@property (nonatomic, retain) DetailViewController *detailViewController;
@property (nonatomic, retain) NSArray *controllerNames;
@property (nonatomic, retain) NSIndexPath *lastIndexPath;

-(IBAction) dismissSplitView;

@end
