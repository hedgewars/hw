//
//  GameConfigViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 18/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GameConfigViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *availableTeamsTableView;
    UIButton *backButton;
    UIButton *mapButton;
    UIButton *randomButton;
    UIButton *weaponsButton;
    UIButton *schemesButton;
    UIButton *startButton;
}

@property (nonatomic,retain) IBOutlet UITableView *availableTeamsTableView;
@property (nonatomic,retain) IBOutlet UIButton *backButton;
@property (nonatomic,retain) IBOutlet UIButton *weaponsButton;
@property (nonatomic,retain) IBOutlet UIButton *schemesButton;
@property (nonatomic,retain) IBOutlet UIButton *mapButton;
@property (nonatomic,retain) IBOutlet UIButton *randomButton;
@property (nonatomic,retain) IBOutlet UIButton *startButton;

-(IBAction) buttonPressed:(id) sender;

@end
