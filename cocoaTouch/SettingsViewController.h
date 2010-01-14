//
//  SettingsViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SettingsViewController : UIViewController {
	UITextField *username;
	UITextField *password;
	UISwitch *musicOn;
	UISwitch *effectsOn;
	UISlider *volumeSlider;
	UILabel *volumeLabel;
}
@property (nonatomic, retain) IBOutlet UITextField *username;
@property (nonatomic, retain) IBOutlet UITextField *password;
@property (nonatomic, retain) IBOutlet UISwitch *musicOn;
@property (nonatomic, retain) IBOutlet UISwitch *effectsOn;
@property (nonatomic, retain) IBOutlet UISlider *volumeSlider;
@property (nonatomic, retain) IBOutlet UILabel *volumeLabel;

-(IBAction) sliderChanged: (id)sender;
-(IBAction) backgroundTap: (id)sender;
-(IBAction) textFieldDoneEditing: (id)sender;
@end
