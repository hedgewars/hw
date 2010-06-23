//
//  CommodityFunctions.h
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_HOGS 8


#define SETTINGS_FILE()         [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                                 objectAtIndex:0] stringByAppendingString:@"/settings.plist"]
#define GAMECONFIG_FILE()       [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                                 objectAtIndex:0] stringByAppendingString:@"/gameconfig.plist"]
#define DEBUG_FILE()            [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                                 objectAtIndex:0] stringByAppendingString:@"/debug.txt"]

#define TEAMS_DIRECTORY()       [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                                 objectAtIndex:0] stringByAppendingString:@"/Teams/"]
#define WEAPONS_DIRECTORY()     [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                                 objectAtIndex:0] stringByAppendingString:@"/Weapons/"]
#define SCHEMES_DIRECTORY()     [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                                 objectAtIndex:0] stringByAppendingString:@"/Schemes/"]

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

void createTeamNamed (NSString *nameWithoutExt);
void createWeaponNamed (NSString *nameWithoutExt);
void createSchemeNamed (NSString *nameWithoutExt);
BOOL rotationManager (UIInterfaceOrientation interfaceOrientation);
NSInteger randomPort ();
void popError (const char *title, const char *message);
void print_free_memory ();

