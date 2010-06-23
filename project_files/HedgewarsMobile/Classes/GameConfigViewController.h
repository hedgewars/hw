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
@class SchemeWeaponConfigViewController;

@interface GameConfigViewController : UIViewController {    
    UIViewController *activeController;
    MapConfigViewController *mapConfigViewController;
    TeamConfigViewController *teamConfigViewController;
    SchemeWeaponConfigViewController *schemeWeaponConfigViewController;
}

-(IBAction) buttonPressed:(id) sender;
-(IBAction) segmentPressed:(id) sender;
-(void) startGame:(UIButton *)button;

@end
