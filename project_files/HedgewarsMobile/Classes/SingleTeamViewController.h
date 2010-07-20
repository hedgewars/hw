//
//  SingleTeamViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditableCellView.h"

@class HogHatViewController;
@class GravesViewController;
@class VoicesViewController;
@class FortsViewController;
@class FlagsViewController;
@class LevelViewController;

@interface SingleTeamViewController : UITableViewController <EditableCellViewDelegate> {
    NSMutableDictionary *teamDictionary;
    
    NSString *teamName;
    UIImage *normalHogSprite;
    
    NSArray *secondaryItems;
    BOOL isWriteNeeded;
    
    HogHatViewController *hogHatViewController;
    GravesViewController *gravesViewController;
    VoicesViewController *voicesViewController;
    FortsViewController *fortsViewController;
    FlagsViewController *flagsViewController;
    LevelViewController *levelViewController;
}

@property (nonatomic,retain) NSMutableDictionary *teamDictionary;
@property (nonatomic,retain) NSString *teamName;
@property (nonatomic,retain) UIImage *normalHogSprite;
@property (nonatomic,retain) NSArray *secondaryItems;

-(void) writeFile;
-(void) setWriteNeeded;

@end
