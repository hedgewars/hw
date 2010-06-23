//
//  WeaponSettingsViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 19/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SingleWeaponViewController;

@interface WeaponSettingsViewController : UITableViewController {
    NSMutableArray *listOfWeapons;
    SingleWeaponViewController *childController;
}

@property (nonatomic, retain) NSMutableArray *listOfWeapons;

@end
