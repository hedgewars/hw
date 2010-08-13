//
//  CommodityFunctions.h
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_HOGS 8

#define DOCUMENTS_FOLDER()      [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define SETTINGS_FILE()         [DOCUMENTS_FOLDER() stringByAppendingString:@"/settings.plist"]
#define DEBUG_FILE()            [DOCUMENTS_FOLDER() stringByAppendingString:@"/debug.txt"]

#define TEAMS_DIRECTORY()       [DOCUMENTS_FOLDER() stringByAppendingString:@"/Teams/"]
#define WEAPONS_DIRECTORY()     [DOCUMENTS_FOLDER() stringByAppendingString:@"/Weapons/"]
#define SCHEMES_DIRECTORY()     [DOCUMENTS_FOLDER() stringByAppendingString:@"/Schemes/"]

#define GRAPHICS_DIRECTORY()    [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/"]
#define HATS_DIRECTORY()        [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hats/"]
#define GRAVES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Graves/"]
#define BOTLEVELS_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hedgehog/botlevels"]
#define BTN_DIRECTORY()         [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Btn"]
#define FLAGS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Flags/"]
#define FORTS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Forts/"]
#define THEMES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Themes/"]
#define MAPS_DIRECTORY()        [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Maps/"]
#define VOICES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Sounds/voices/"]

#define MSG_MEMCLEAN()          DLog(@"has cleaned up some memory");
#define MSG_DIDUNLOAD()         DLog(@"unloaded");

#define CURRENT_AMMOSIZE        48      // also add a line in SingleWeaponViewController array

#define UICOLOR_HW_YELLOW_BODER [UIColor colorWithRed:(CGFloat)0xFE/255 green:(CGFloat)0xC0/255 blue:0 alpha:1]
#define UICOLOR_HW_YELLOW_TEXT  [UIColor colorWithRed:(CGFloat)0xF0/255 green:(CGFloat)0xD0/255 blue:0 alpha:1]

void createTeamNamed (NSString *nameWithoutExt);
void createWeaponNamed (NSString *nameWithoutExt, int type);
void createSchemeNamed (NSString *nameWithoutExt);
BOOL rotationManager (UIInterfaceOrientation interfaceOrientation);
NSInteger randomPort ();
void popError (const char *title, const char *message);
void print_free_memory ();
BOOL isPhone ();
NSString *modelType ();
