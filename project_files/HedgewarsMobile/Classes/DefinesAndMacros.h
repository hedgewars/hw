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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


// some macros by http://www.cimgf.com/2010/05/02/my-current-prefix-pch-file/
// and http://blog.coriolis.ch/2009/01/05/macros-for-xcode/


#ifdef DEBUG
  #define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
  #define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#else
  #ifndef NS_BLOCK_ASSERTIONS
    #define NS_BLOCK_ASSERTIONS
  #endif
  #define DLog(...)
  #define ALog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#endif


#define ZAssert(condition, ...) do { if (!(condition)) { ALog(__VA_ARGS__); }} while(0)
#define rotationManager(x) (IS_IPAD() ? YES : (x == UIInterfaceOrientationLandscapeRight) || (x == UIInterfaceOrientationLandscapeLeft))

#define START_TIMER()   NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
#define END_TIMER(msg)  NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate]; DLog([NSString stringWithFormat:@"%@ Time = %f", msg, stop-start]);


#define DOCUMENTS_FOLDER()      [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define DEBUG_FILE()            [DOCUMENTS_FOLDER() stringByAppendingString:@"/Logs/game0.log"]
#define BASICFLAGS_FILE()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/basicFlags.plist"]
#define GAMEMODS_FILE()         [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/gameMods.plist"]
#define CREDITS_FILE()          [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/credits.plist"]

#define TEAMS_DIRECTORY()       [DOCUMENTS_FOLDER() stringByAppendingString:@"/Teams/"]
#define WEAPONS_DIRECTORY()     [DOCUMENTS_FOLDER() stringByAppendingString:@"/Weapons/"]
#define SCHEMES_DIRECTORY()     [DOCUMENTS_FOLDER() stringByAppendingString:@"/Schemes/"]
#define SAVES_DIRECTORY()       [DOCUMENTS_FOLDER() stringByAppendingString:@"/Saves/"]
#define SCREENSHOTS_DIRECTORY() [DOCUMENTS_FOLDER() stringByAppendingString:@"/Screenshots/"]

#define GRAPHICS_DIRECTORY()    [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/"]
#define ICONS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Icons/"]
#define HATS_DIRECTORY()        [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hats/"]
#define GRAVES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Graves/"]
#define FLAGS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Flags/"]
#define FORTS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Forts/"]
#define VOICES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Sounds/voices/"]
#define THEMES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Themes/"]
#define MAPS_DIRECTORY()        [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Maps/"]
#define MISSIONS_DIRECTORY()    [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Missions/Maps/"]
#define TRAININGS_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Missions/Training/"]
#define SCENARIO_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Missions/Scenario/"]
#define CHALLENGE_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Missions/Challenge/"]
#define CAMPAIGNS_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Missions/Campaign/"]
#define LOCALE_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Locale/"]
#define SCRIPTS_DIRECTORY()     [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Scripts/Multiplayer/"]

#define MSG_MEMCLEAN()          DLog(@"has cleaned up some memory");
#define MSG_DIDUNLOAD()         DLog(@"unloaded");

#define IS_IPAD()               (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_ON_PORTRAIT()        (IS_IPAD() && UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
#define IS_NOT_POWERFUL(x)      ([x hasPrefix:@"iPhone1"] || [x hasPrefix:@"iPod1,1"] || [x hasPrefix:@"iPod2,1"])
#define IS_NOT_VERY_POWERFUL(x) ([x hasPrefix:@"iPad1"] || [x hasPrefix:@"iPhone2"] || [x hasPrefix:@"iPod3"] || [x hasPrefix:@"iPod4"])
#define IS_VERY_POWERFUL(x)     (IS_NOT_POWERFUL(x) == NO && IS_NOT_VERY_POWERFUL(x) == NO)

