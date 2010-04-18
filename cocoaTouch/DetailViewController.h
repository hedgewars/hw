//
//  DetailViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 27/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GeneralSettingsViewController;
@class TeamSettingsViewController;
@class WeaponSettingsViewController;
@class SchemeSettingsViewController;
#ifdef __IPHONE_3_2
@interface DetailViewController : UITableViewController <UIPopoverControllerDelegate, UISplitViewControllerDelegate> {
#else
@interface DetailViewController : UITableViewController {
#endif
    id popoverController;
    NSArray *controllerNames;
    GeneralSettingsViewController *generalSettingsViewController;
    TeamSettingsViewController *teamSettingsViewController;
    WeaponSettingsViewController *weaponSettingsViewController;
    SchemeSettingsViewController *schemeSettingsViewController;
}

// used in iphone version
-(IBAction) dismissSplitView;

@property (nonatomic, retain) id popoverController;
@property (nonatomic, retain) NSArray *controllerNames;

@end
