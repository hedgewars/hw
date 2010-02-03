//
//  MainMenuViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@interface MainMenuViewController : UIViewController {
	UILabel *versionLabel;
	SettingsViewController *settingsViewController;
}

@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) SettingsViewController *settingsViewController;

-(IBAction) startPlaying;
-(IBAction) notYetImplemented;
-(IBAction) switchViews:(id)sender;
@end
