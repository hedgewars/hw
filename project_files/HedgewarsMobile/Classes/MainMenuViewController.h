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

@interface MainMenuViewController : UIViewController {
    UILabel *versionLabel;
    SplitViewRootController *settingsViewController;
    GameConfigViewController *gameConfigViewController;
}

@property (nonatomic,retain) IBOutlet UILabel *versionLabel;

-(IBAction) switchViews:(id)sender;
@end
