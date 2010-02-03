//
//  SettingsViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SettingsViewController : UIViewController 
		<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
	UITextField *username;
	UITextField *password;
	UISwitch *musicSwitch;
	UISwitch *soundsSwitch;
	UISwitch *altDamageSwitch;
	UITableView *settingsTable;
	UITableViewCell *volumeCell;
	UIView *buttonContainer;
	UIView *parentView;
	BOOL needsReset;
}

@property (nonatomic, retain) IBOutlet UITextField *username;
@property (nonatomic, retain) IBOutlet UITextField *password;
@property (nonatomic, retain) UISwitch *musicSwitch;
@property (nonatomic, retain) UISwitch *soundsSwitch;
@property (nonatomic, retain) UISwitch *altDamageSwitch;
@property (nonatomic, retain) IBOutlet UITableView *settingsTable;
@property (nonatomic, retain) IBOutlet UIView *buttonContainer;
@property (nonatomic, retain) UIView *parentView;

-(IBAction) backgroundTap: (id)sender;
-(IBAction) textFieldDoneEditing: (id)sender;
-(IBAction) deleteData: (id)sender;
@end
