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

@interface DetailViewController : UITableViewController
#if __IPHONE_3_2
<UISplitViewControllerDelegate, UIPopoverControllerDelegate>
#endif
{
    NSArray *controllerNames;
    
    GeneralSettingsViewController *generalSettingsViewController;
    TeamSettingsViewController *teamSettingsViewController;
    WeaponSettingsViewController *weaponSettingsViewController;
    SchemeSettingsViewController *schemeSettingsViewController;
    UIPopoverController *popoverController;
}

// used in iphone version
-(IBAction) dismissSplitView;

@property (nonatomic, retain) NSArray *controllerNames;
@property (nonatomic,retain) UIPopoverController *popoverController;

@end
