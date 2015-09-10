/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import <UIKit/UIKit.h>


@class SchemeWeaponConfigViewController;
@class TeamConfigViewController;
@class MapConfigViewController;
@class HelpPageLobbyViewController;

@interface GameConfigViewController : UIViewController {
    UIView *imgContainer;
    UIImageView *titleImage;
    UILabel *sliderBackground;

    SchemeWeaponConfigViewController *schemeWeaponConfigViewController;
    TeamConfigViewController *teamConfigViewController;
    MapConfigViewController *mapConfigViewController;
    HelpPageLobbyViewController *helpPage;
}

@property (retain) UIView *imgContainer;
@property (nonatomic,retain) UILabel * sliderBackground;
@property (nonatomic,retain) IBOutlet UIImageView *titleImage;
@property (nonatomic,retain) IBOutlet SchemeWeaponConfigViewController *schemeWeaponConfigViewController;
@property (nonatomic,retain) IBOutlet TeamConfigViewController *teamConfigViewController;
@property (nonatomic,retain) IBOutlet MapConfigViewController *mapConfigViewController;
@property (nonatomic,retain) HelpPageLobbyViewController *helpPage;

-(IBAction) buttonPressed:(id) sender;
-(IBAction) segmentPressed:(id) sender;
-(void) startGame:(UIButton *)button;
-(BOOL) isEverythingSet;

@end
