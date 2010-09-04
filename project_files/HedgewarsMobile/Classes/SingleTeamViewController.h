/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 02/04/2010.
 */


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
    NSArray *moreSecondaryItems;
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
@property (nonatomic,retain) NSArray *moreSecondaryItems;

-(void) writeFile;
-(void) setWriteNeeded;

@end
