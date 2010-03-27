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
    UIView *cover;
}

@property (nonatomic,retain) UIView *cover;

-(void) appear;
-(void) disappear;

-(IBAction) switchViews:(id)sender;
@end
