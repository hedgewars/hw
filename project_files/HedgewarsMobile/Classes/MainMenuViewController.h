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
 * File created on 08/01/2010.
 */


#import <UIKit/UIKit.h>

@class SplitViewRootController;
@class GameConfigViewController;
@class AboutViewController;

@interface MainMenuViewController : UIViewController {
    UILabel *versionLabel;
    GameConfigViewController *gameConfigViewController;
    SplitViewRootController *settingsViewController;
    AboutViewController *aboutViewController;
}

@property (nonatomic,retain) IBOutlet UILabel *versionLabel;
@property (nonatomic,retain) GameConfigViewController *gameConfigViewController;
@property (nonatomic,retain) SplitViewRootController *settingsViewController;
@property (nonatomic,retain) AboutViewController *aboutViewController;

-(IBAction) switchViews:(id)sender;

@end
