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
 * File created on 12/11/2010.
 */


#import "CreationChamber.h"

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

    NSDictionary *theWeapon = nil;
    switch (type) {
        case 0: //default
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"9391929422199121032235111001201000000211110101011",@"ammostore_initialqt",
                         @"0405040541600655546554464776576666666155510101117",@"ammostore_probability",
                         @"0000000000000205500000040007004000000000200000000",@"ammostore_delay",
                         @"1311110312111111123114111111111111111211111101111",@"ammostore_crate", nil];
            break;
        case 1: //crazy
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"9999999999999999992999999999999999299999999909999",@"ammostore_initialqt",
                         @"1111110111111111111111111111111111111111111101111",@"ammostore_probability",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"1311110312111111123114111111111111111211110101111",@"ammostore_crate", nil];
            break;
        case 2: //pro mode
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"9090009000000000000009000000000000000000000000000",@"ammostore_initialqt",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"0000000000000205500000040007004000000000200000000",@"ammostore_delay",
                         @"1111111111111111111111111111111111111111100101111",@"ammostore_crate", nil];
            break;
        case 3: //shoppa
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"0000009900000000000000000000000000000000000000000",@"ammostore_initialqt",
                         @"4444410044244402210112121222422000000002000400010",@"ammostore_probability",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"1111111111111111111111111111111111111111101101111",@"ammostore_crate", nil];
            break;
        case 4: //clean slate
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"1010009000010000011000000000000000000000000000001",@"ammostore_initialqt",
                         @"0405040541600655546554464776576666666155510101117",@"ammostore_probability",
                         @"0000000000000205500000040007004000000000200000000",@"ammostore_delay",
                         @"1311110312111111123114111111111111111211111101111",@"ammostore_crate", nil];
            break;
        case 5: //minefield
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"0000009900090000000300000000000000000000000000000",@"ammostore_initialqt",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"0000000000000205500000040007004000000000200000000",@"ammostore_delay",
                         @"1111111111111111111111111111111111111111111101111",@"ammostore_crate", nil];
            break;
        default:
            NSLog(@"Nope");
            break;
    }

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

    NSMutableArray *basicArray  = [[NSMutableArray alloc] initWithObjects:
                                   [NSNumber numberWithInt:100],      //initialhealth
                                   [NSNumber numberWithInt:45],       //turntime
                                   [NSNumber numberWithInt:100],      //damagemodifier
                                   [NSNumber numberWithInt:15],       //suddendeathtimeout
                                   [NSNumber numberWithInt:47],       //waterrise
                                   [NSNumber numberWithInt:5],        //healthdecrease
                                   [NSNumber numberWithInt:5],        //cratedrops
                                   [NSNumber numberWithInt:35],       //healthprob
                                   [NSNumber numberWithInt:25],       //healthamount
                                   [NSNumber numberWithInt:3],        //minestime
                                   [NSNumber numberWithInt:4],        //minesnumber
                                   [NSNumber numberWithInt:0],        //dudmines
                                   [NSNumber numberWithInt:2],        //explosives
                                   nil];

    NSMutableArray *gamemodArray= [[NSMutableArray alloc] initWithObjects:
                                   [NSNumber numberWithBool:NO],      //fortmode
                                   [NSNumber numberWithBool:NO],      //divideteam
                                   [NSNumber numberWithBool:NO],      //solidland
                                   [NSNumber numberWithBool:NO],      //addborder
                                   [NSNumber numberWithBool:NO],      //lowgravity
                                   [NSNumber numberWithBool:NO],      //lasersight
                                   [NSNumber numberWithBool:NO],      //invulnerable
                                   [NSNumber numberWithBool:NO],      //resethealth
                                   [NSNumber numberWithBool:NO],      //vampirism
                                   [NSNumber numberWithBool:NO],      //karma
                                   [NSNumber numberWithBool:NO],      //artillery
                                   [NSNumber numberWithBool:YES],     //randomorder
                                   [NSNumber numberWithBool:NO],      //king
                                   [NSNumber numberWithBool:NO],      //placehedgehogs
                                   [NSNumber numberWithBool:NO],      //clansharesammo
                                   [NSNumber numberWithBool:NO],      //disablegirders
                                   [NSNumber numberWithBool:NO],      //disablelandobjects
                                   [NSNumber numberWithBool:NO],      //aisurvival
                                   [NSNumber numberWithBool:NO],      //infattack
                                   [NSNumber numberWithBool:NO],      //resetweaps
                                   [NSNumber numberWithBool:NO],      //perhogammo
                                   nil];
    
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
