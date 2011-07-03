/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * File created on 12/11/2010.
 */


#import "CreationChamber.h"
#import "hwconsts.h"

void createSettings () {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithBool:NO] forKey:@"alternate"];
    [settings setObject:[NSNumber numberWithBool:YES] forKey:@"music"];
    [settings setObject:[NSNumber numberWithBool:YES] forKey:@"sound"];
    [settings setObject:[NSNumber numberWithBool:NO] forKey:@"classic_menu"];
    [settings setObject:[NSNumber numberWithBool:YES] forKey:@"enhanced"];
    [settings setObject:[NSNumber numberWithBool:YES] forKey:@"multitasking"];

    // don't overwrite these two strings when present
    if ([settings objectForKey:@"username"] == nil)
        [settings setObject:@"" forKey:@"username"];
    if ([settings objectForKey:@"password"] == nil)
        [settings setObject:@"" forKey:@"password"];

    [settings synchronize];
}

void createTeamNamed (NSString *nameWithoutExt) {
    NSString *teamsDirectory = TEAMS_DIRECTORY();

    if (![[NSFileManager defaultManager] fileExistsAtPath: teamsDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:teamsDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }

    NSMutableArray *hedgehogs = [[NSMutableArray alloc] initWithCapacity: HW_getMaxNumberOfHogs()];

    for (int i = 0; i < HW_getMaxNumberOfHogs(); i++) {
        NSString *hogName = [[NSString alloc] initWithFormat:@"hedgehog %d",i];
        NSDictionary *hog = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [NSNumber numberWithInt:0],@"level",
                             hogName,@"hogname",
                             @"NoHat",@"hat",
                             nil];
        [hogName release];
        [hedgehogs addObject:hog];
        [hog release];
    }

    NSDictionary *theTeam = [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"0",@"hash",
                             @"Statue",@"grave",
                             @"Plane",@"fort",
                             @"Default",@"voicepack",
                             @"hedgewars",@"flag",
                             hedgehogs,@"hedgehogs",
                             nil];
    [hedgehogs release];

    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist", teamsDirectory, nameWithoutExt];

    [theTeam writeToFile:teamFile atomically:YES];
    [teamFile release];
    [theTeam release];
}

void createWeaponNamed (NSString *nameWithoutExt, int type) {
    NSString *weaponsDirectory = WEAPONS_DIRECTORY();

    if (![[NSFileManager defaultManager] fileExistsAtPath: weaponsDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:weaponsDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }

    NSInteger ammolineSize = HW_getNumberOfWeapons();
    NSString *qt, *prob, *delay, *crate;
    switch (type) {
        default: //default
            qt = [[NSString alloc] initWithBytes:AMMOLINE_DEFAULT_QT length:ammolineSize encoding:NSUTF8StringEncoding];
            prob = [[NSString alloc] initWithBytes:AMMOLINE_DEFAULT_PROB length:ammolineSize encoding:NSUTF8StringEncoding];
            delay = [[NSString alloc] initWithBytes:AMMOLINE_DEFAULT_DELAY length:ammolineSize encoding:NSUTF8StringEncoding];
            crate = [[NSString alloc] initWithBytes:AMMOLINE_DEFAULT_CRATE length:ammolineSize encoding:NSUTF8StringEncoding];
            break;
        case 1: //crazy
            qt = [[NSString alloc] initWithBytes:AMMOLINE_CRAZY_QT length:ammolineSize encoding:NSUTF8StringEncoding];
            prob = [[NSString alloc] initWithBytes:AMMOLINE_CRAZY_PROB length:ammolineSize encoding:NSUTF8StringEncoding];
            delay = [[NSString alloc] initWithBytes:AMMOLINE_CRAZY_DELAY length:ammolineSize encoding:NSUTF8StringEncoding];
            crate = [[NSString alloc] initWithBytes:AMMOLINE_CRAZY_CRATE length:ammolineSize encoding:NSUTF8StringEncoding];
            break;
        case 2: //pro mode
            qt = [[NSString alloc] initWithBytes:AMMOLINE_PROMODE_QT length:ammolineSize encoding:NSUTF8StringEncoding];
            prob = [[NSString alloc] initWithBytes:AMMOLINE_PROMODE_PROB length:ammolineSize encoding:NSUTF8StringEncoding];
            delay = [[NSString alloc] initWithBytes:AMMOLINE_PROMODE_DELAY length:ammolineSize encoding:NSUTF8StringEncoding];
            crate = [[NSString alloc] initWithBytes:AMMOLINE_PROMODE_CRATE length:ammolineSize encoding:NSUTF8StringEncoding];
            break;
        case 3: //shoppa
            qt = [[NSString alloc] initWithBytes:AMMOLINE_SHOPPA_QT length:ammolineSize encoding:NSUTF8StringEncoding];
            prob = [[NSString alloc] initWithBytes:AMMOLINE_SHOPPA_PROB length:ammolineSize encoding:NSUTF8StringEncoding];
            delay = [[NSString alloc] initWithBytes:AMMOLINE_SHOPPA_DELAY length:ammolineSize encoding:NSUTF8StringEncoding];
            crate = [[NSString alloc] initWithBytes:AMMOLINE_SHOPPA_CRATE length:ammolineSize encoding:NSUTF8StringEncoding];
            break;
        case 4: //clean slate
            qt = [[NSString alloc] initWithBytes:AMMOLINE_CLEAN_QT length:ammolineSize encoding:NSUTF8StringEncoding];
            prob = [[NSString alloc] initWithBytes:AMMOLINE_CLEAN_PROB length:ammolineSize encoding:NSUTF8StringEncoding];
            delay = [[NSString alloc] initWithBytes:AMMOLINE_CLEAN_DELAY length:ammolineSize encoding:NSUTF8StringEncoding];
            crate = [[NSString alloc] initWithBytes:AMMOLINE_CLEAN_CRATE length:ammolineSize encoding:NSUTF8StringEncoding];
            break;
        case 5: //minefield
            qt = [[NSString alloc] initWithBytes:AMMOLINE_MINES_QT length:ammolineSize encoding:NSUTF8StringEncoding];
            prob = [[NSString alloc] initWithBytes:AMMOLINE_MINES_PROB length:ammolineSize encoding:NSUTF8StringEncoding];
            delay = [[NSString alloc] initWithBytes:AMMOLINE_MINES_DELAY length:ammolineSize encoding:NSUTF8StringEncoding];
            crate = [[NSString alloc] initWithBytes:AMMOLINE_MINES_CRATE length:ammolineSize encoding:NSUTF8StringEncoding];
            break;
        case 6: //thinking with portals
            qt = [[NSString alloc] initWithBytes:AMMOLINE_PORTALS_QT length:ammolineSize encoding:NSUTF8StringEncoding];
            prob = [[NSString alloc] initWithBytes:AMMOLINE_PORTALS_PROB length:ammolineSize encoding:NSUTF8StringEncoding];
            delay = [[NSString alloc] initWithBytes:AMMOLINE_PORTALS_DELAY length:ammolineSize encoding:NSUTF8StringEncoding];
            crate = [[NSString alloc] initWithBytes:AMMOLINE_PORTALS_CRATE length:ammolineSize encoding:NSUTF8StringEncoding];
            break;
    }

    NSDictionary *theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys: qt,@"ammostore_initialqt",
                               prob,@"ammostore_probability", delay,@"ammostore_delay", crate,@"ammostore_crate", nil];
    [qt release];
    [prob release];
    [delay release];
    [crate release];

    NSString *weaponFile = [[NSString alloc] initWithFormat:@"%@/%@.plist", weaponsDirectory, nameWithoutExt];
    [theWeapon writeToFile:weaponFile atomically:YES];
    [weaponFile release];
    [theWeapon release];
}

void createSchemeNamed (NSString *nameWithoutExt) {
    NSString *schemesDirectory = SCHEMES_DIRECTORY();

    if (![[NSFileManager defaultManager] fileExistsAtPath: schemesDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:schemesDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }

    // load data to get the size of the arrays and their default values
    NSArray *basicSettings = [[NSArray alloc] initWithContentsOfFile:BASICFLAGS_FILE()];
    NSMutableArray *basicArray  = [[NSMutableArray alloc] initWithCapacity:[basicSettings count]];
    for (NSDictionary *basicDict in basicSettings)
        [basicArray addObject:[basicDict objectForKey:@"default"]];
    [basicSettings release];

    NSArray *mods = [[NSArray alloc] initWithContentsOfFile:GAMEMODS_FILE()];
    NSMutableArray *gamemodArray= [[NSMutableArray alloc] initWithCapacity:[mods count]];
    for (int i = 0; i < [mods count]; i++)
        [gamemodArray addObject:[NSNumber numberWithBool:NO]];
    [mods release];

    // workaround for randomorder that has to be set to YES
    [gamemodArray replaceObjectAtIndex:11 withObject:[NSNumber numberWithBool:YES]];

    NSMutableDictionary *theScheme = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      basicArray,@"basic",
                                      gamemodArray,@"gamemod",
                                      nil];
    [gamemodArray release];
    [basicArray release];
    
    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@.plist", schemesDirectory, nameWithoutExt];
    
    [theScheme writeToFile:schemeFile atomically:YES];
    [schemeFile release];
    [theScheme release];
}
