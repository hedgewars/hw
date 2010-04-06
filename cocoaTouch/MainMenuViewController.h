//
//  MainMenuViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainMenuViewController : UIViewController {
    UIView *cover;
    UILabel *versionLabel;
}

@property (nonatomic,retain) UIView *cover;
@property (nonatomic,retain) IBOutlet UILabel *versionLabel;

-(void) appear;
-(void) disappear;
-(void) hideBehind;

-(IBAction) switchViews:(id)sender;
@end
