//
//  GameConfigViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 18/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TeamConfigViewController;
@class MapConfigViewController;

@interface GameConfigViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *availableTeamsTableView;
    UIButton *mapButton;
    UIButton *randomButton;
    UIButton *weaponsButton;
    UIButton *schemesButton;
    UIBarButtonItem *startButton;
    
    UIViewController *activeController;
    MapConfigViewController *mapConfigViewController;
    TeamConfigViewController *teamConfigViewController;
}

@property (nonatomic,retain) IBOutlet UITableView *availableTeamsTableView;
@property (nonatomic,retain) IBOutlet UIButton *weaponsButton;
@property (nonatomic,retain) IBOutlet UIButton *schemesButton;
@property (nonatomic,retain) IBOutlet UIButton *mapButton;
@property (nonatomic,retain) IBOutlet UIButton *randomButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *startButton;

-(IBAction) buttonPressed:(id) sender;
-(IBAction) segmentPressed:(id) sender;
-(void) startGame;

@end
