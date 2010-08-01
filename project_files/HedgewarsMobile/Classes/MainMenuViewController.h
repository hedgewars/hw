//
//  MainMenuViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SplitViewRootController;
@class GameConfigViewController;
@class AboutViewController;

@interface MainMenuViewController : UIViewController {
    UILabel *versionLabel;
    GameConfigViewController *gameConfigViewController;
    SplitViewRootController *settingsViewController;
    AboutViewController *aboutViewController;
}

@property (nonatomic,retain) IBOutlet UILabel *versionLabel;
@property (nonatomic,retain) GameConfigViewController *gameConfigViewController;
@property (nonatomic,retain) SplitViewRootController *settingsViewController;
@property (nonatomic,retain) AboutViewController *aboutViewController;

-(IBAction) switchViews:(id)sender;

@end
