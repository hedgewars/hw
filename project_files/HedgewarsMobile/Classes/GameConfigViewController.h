//
//  GameConfigViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 18/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapConfigViewController.h"

@class TeamConfigViewController;
@class SchemeWeaponConfigViewController;

@interface GameConfigViewController : UIViewController <MapConfigDelegate> {
    UIImage *hedgehogImage;
    UIView *imgContainer;
    
    UIViewController *activeController;
    MapConfigViewController *mapConfigViewController;
    TeamConfigViewController *teamConfigViewController;
    SchemeWeaponConfigViewController *schemeWeaponConfigViewController;
}

@property (nonatomic,retain) UIImage *hedgehogImage;
@property (nonatomic,retain) UIView *imgContainer;

-(IBAction) buttonPressed:(id) sender;
-(IBAction) segmentPressed:(id) sender;
-(void) startGame:(UIButton *)button;

@end
