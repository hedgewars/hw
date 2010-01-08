//
//  MainMenuViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainMenuViewController : UIViewController {
	UIButton *passandplayButton;
	UIButton *netplayButton;
	UIButton *storeButton;
	UILabel *versionLabel;
}

@property (nonatomic, retain) IBOutlet UIButton *passandplayButton;
@property (nonatomic, retain) IBOutlet UIButton *netplayButton;
@property (nonatomic, retain) IBOutlet UIButton *storeButton;
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;

-(IBAction) startPlaying;
-(IBAction) notYetImplemented;
@end
