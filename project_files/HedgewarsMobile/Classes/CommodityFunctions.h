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
 * File created on 08/04/2010.
 */


#import <Foundation/Foundation.h>

#define DOCUMENTS_FOLDER()      [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define SETTINGS_FILE()         [DOCUMENTS_FOLDER() stringByAppendingString:@"/settings.plist"]
#define DEBUG_FILE()            [DOCUMENTS_FOLDER() stringByAppendingString:@"/hw-game.log"]

#define TEAMS_DIRECTORY()       [DOCUMENTS_FOLDER() stringByAppendingString:@"/Teams/"]
#define WEAPONS_DIRECTORY()     [DOCUMENTS_FOLDER() stringByAppendingString:@"/Weapons/"]
#define SCHEMES_DIRECTORY()     [DOCUMENTS_FOLDER() stringByAppendingString:@"/Schemes/"]
#define SAVES_DIRECTORY()       [DOCUMENTS_FOLDER() stringByAppendingString:@"/Saves/"]

#define GRAPHICS_DIRECTORY()    [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/"]
#define HATS_DIRECTORY()        [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hats/"]
#define GRAVES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Graves/"]
#define BOTLEVELS_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hedgehog/botlevels/"]
#define BTN_DIRECTORY()         [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Btn/"]
#define FLAGS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Flags/"]
#define FORTS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Forts/"]
#define VOICES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Sounds/voices/"]
#define THEMES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Themes/"]
#define MAPS_DIRECTORY()        [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Maps/"]
#define MISSIONS_DIRECTORY()    [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Missions/Maps/"]
#define LOCALE_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Locale/"]
#define IFRONTEND_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Settings/iFrontend/"]

#define MSG_MEMCLEAN()          DLog(@"has cleaned up some memory");
#define MSG_DIDUNLOAD()         DLog(@"unloaded");

#define UICOLOR_HW_YELLOW_BODER [UIColor colorWithRed:(CGFloat)0xFE/255 green:(CGFloat)0xC0/255 blue:0 alpha:1]
#define UICOLOR_HW_YELLOW_TEXT  [UIColor colorWithRed:(CGFloat)0xF0/255 green:(CGFloat)0xD0/255 blue:0 alpha:1]
#define UICOLOR_HW_DARKBLUE     [UIColor colorWithRed:(CGFloat)0x0F/255 green:0 blue:(CGFloat)0x42/255 alpha:1]
#define UICOLOR_HW_ALPHABLUE    [UIColor colorWithRed:(CGFloat)0x0F/255 green:0 blue:(CGFloat)0x42/255 alpha:0.58f]

#define IS_DUALHEAD()           ([[UIScreen class] respondsToSelector:@selector(screens)] && [[UIScreen screens] count] > 1)
#define IS_IPAD()               (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_NOT_POWERFUL()       ([modelType() hasPrefix:@"iPhone1"] || [modelType() hasPrefix:@"iPod1,1"] || [modelType() hasPrefix:@"iPod2,1"])

#define DEFAULT_NETGAME_PORT    46631


void print_free_memory (void);
void playSound (NSString *snd);
void popError (const char *title, const char *message);
BOOL rotationManager (UIInterfaceOrientation interfaceOrientation);
BOOL isApplePhone (void);
NSInteger randomPort (void);
NSString *modelType (void);
NSArray *getAvailableColors (void);
UILabel *createBlueLabel (NSString *title, CGRect frame);
UILabel *createLabelWithParams (NSString *title, CGRect frame, CGFloat borderWidth, UIColor *borderColor, UIColor *backgroundColor);

CGSize PSPNGSizeFromMetaData (NSString *aFileName);
