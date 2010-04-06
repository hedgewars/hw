//
//  SettingsViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GeneralSettingsViewController : UITableViewController <UIActionSheetDelegate> {
    NSDictionary *dataDict;
	NSString *username;
	NSString *password;
	UISwitch *musicSwitch;
	UISwitch *soundSwitch;
	UISwitch *altDamageSwitch;
}

@property (nonatomic, retain) NSDictionary *dataDict;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) UISwitch *musicSwitch;
@property (nonatomic, retain) UISwitch *soundSwitch;
@property (nonatomic, retain) UISwitch *altDamageSwitch;

#define kNetworkFields 0
#define kAudioFields 1
#define kOtherFields 2

@end
