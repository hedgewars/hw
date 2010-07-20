//
//  SettingsViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GeneralSettingsViewController : UITableViewController <UITextFieldDelegate> {
    NSMutableDictionary *settingsDictionary;
    UITextField *textFieldBeingEdited;
    UISwitch *musicSwitch;
    UISwitch *soundSwitch;
    UISwitch *altDamageSwitch;
}

@property (nonatomic, retain) NSMutableDictionary *settingsDictionary;
@property (nonatomic, retain) UITextField *textFieldBeingEdited;;
@property (nonatomic, retain) UISwitch *musicSwitch;
@property (nonatomic, retain) UISwitch *soundSwitch;
@property (nonatomic, retain) UISwitch *altDamageSwitch;

@end
