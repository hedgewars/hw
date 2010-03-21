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
	UIView *mainView;
	SettingsViewController *settingsViewController;
}

@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UIView *mainView;
@property (nonatomic, retain) SettingsViewController *settingsViewController;

-(void) appear;
-(void) disappear;

-(IBAction) startPlaying;
-(IBAction) notYetImplemented;
-(IBAction) switchViews:(id)sender;
@end
