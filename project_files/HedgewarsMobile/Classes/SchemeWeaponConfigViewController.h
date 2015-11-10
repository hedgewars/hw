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


@interface SchemeWeaponConfigViewController : UIViewController <UITableViewDelegate,UITableViewDataSource> {
    NSArray *listOfSchemes;
    NSArray *listOfWeapons;
    NSArray *listOfScripts;

    NSIndexPath *lastIndexPath_sc;
    NSIndexPath *lastIndexPath_we;
    NSIndexPath *lastIndexPath_lu;

    NSString *selectedScheme;
    NSString *selectedWeapon;
    NSString *selectedScript;
    NSString *scriptCommand;

    UISegmentedControl *topControl;
    BOOL sectionsHidden;
}

@property (nonatomic,retain) NSArray *listOfSchemes;
@property (nonatomic,retain) NSArray *listOfWeapons;
@property (nonatomic,retain) NSArray *listOfScripts;
@property (nonatomic,retain) NSIndexPath *lastIndexPath_sc;
@property (nonatomic,retain) NSIndexPath *lastIndexPath_we;
@property (nonatomic,retain) NSIndexPath *lastIndexPath_lu;
@property (nonatomic,retain) NSString *selectedScheme;
@property (nonatomic,retain) NSString *selectedWeapon;
@property (nonatomic,retain) NSString *selectedScript;
@property (nonatomic,retain) NSString *scriptCommand;
@property (nonatomic,retain) UISegmentedControl *topControl;
@property (nonatomic,assign) BOOL sectionsHidden;

-(void) fillSections;
-(void) emptySections;

@end
