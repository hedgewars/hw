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
        default: //default
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"939192942219912103223511100120100000021111010101112",@"ammostore_initialqt",
                         @"040504054160065554655446477657666666615551010111541",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000060",@"ammostore_delay",
                         @"131111031211111112311411111111111111121111110111112",@"ammostore_crate", nil];
            break;
        case 1: //crazy
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"999999999999999999299999999999999929999999990999999",@"ammostore_initialqt",
                         @"111111011111111111111111111111111111111111110111111",@"ammostore_probability",
                         @"000000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"131111031211111112311411111111111111121111010111111",@"ammostore_crate", nil];
            break;
        case 2: //pro mode
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"909000900000000000000900000000000000000000000000000",@"ammostore_initialqt",
                         @"000000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000000",@"ammostore_delay",
                         @"111111111111111111111111111111111111111110010111111",@"ammostore_crate", nil];
            break;
        case 3: //shoppa
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"000000990000000000000000000000000000000000000000000",@"ammostore_initialqt",
                         @"444441004424440221011212122242200000000200040001001",@"ammostore_probability",
                         @"000000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"111111111111111111111111111111111111111110110111111",@"ammostore_crate", nil];
            break;
        case 4: //clean slate
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"101000900001000001100000000000000000000000000000100",@"ammostore_initialqt",
                         @"040504054160065554655446477657666666615551010111541",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000000",@"ammostore_delay",
                         @"131111031211111112311411111111111111121111110111111",@"ammostore_crate", nil];
            break;
        case 5: //minefield
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"000000990009000000030000000000000000000000000000000",@"ammostore_initialqt",
                         @"000000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000000",@"ammostore_delay",
                         @"111111111111111111111111111111111111111111110111111",@"ammostore_crate", nil];
            break;
        case 6: //thinking with portals
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"900000900200000000210000000000000011000009000000000",@"ammostore_initialqt",
                         @"040504054160065554655446477657666666615551010111541",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000060",@"ammostore_delay",
                         @"131111031211111112311411111111111111121111110111111",@"ammostore_crate", nil];
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

    int basicFlags[] = {100, 100, 45, 15, 47, 5, 100, 5, 35, 25, 3, 4, 0, 2};
    BOOL gameFlags[] = {NO, NO, NO, NO, NO, NO, NO, NO, NO, NO, NO, YES, NO, NO, NO, NO,
        NO, NO, NO, NO, NO, NO, NO};

    NSMutableArray *basicArray  = [[NSMutableArray alloc] initWithObjects:
                                   [NSNumber numberWithInt:basicFlags[0]],          //initialhealth
                                   [NSNumber numberWithInt:basicFlags[1]],          //damagemodifier
                                   [NSNumber numberWithInt:basicFlags[2]],          //turntime
                                   [NSNumber numberWithInt:basicFlags[3]],          //suddendeathtimeout
                                   [NSNumber numberWithInt:basicFlags[4]],          //waterrise
                                   [NSNumber numberWithInt:basicFlags[5]],          //healthdecrease
                                   [NSNumber numberWithInt:basicFlags[6]],          //ropelength
                                   [NSNumber numberWithInt:basicFlags[7]],          //cratedrops
                                   [NSNumber numberWithInt:basicFlags[8]],          //healthprob
                                   [NSNumber numberWithInt:basicFlags[9]],          //healthamount
                                   [NSNumber numberWithInt:basicFlags[10]],         //minestime
                                   [NSNumber numberWithInt:basicFlags[11]],         //minesnumber
                                   [NSNumber numberWithInt:basicFlags[12]],         //dudmines
                                   [NSNumber numberWithInt:basicFlags[13]],         //explosives
                                   nil];

    NSMutableArray *gamemodArray= [[NSMutableArray alloc] initWithObjects:
                                   [NSNumber numberWithBool:gameFlags[0]],          //fortmode
                                   [NSNumber numberWithBool:gameFlags[1]],          //divideteam
                                   [NSNumber numberWithBool:gameFlags[2]],          //solidland
                                   [NSNumber numberWithBool:gameFlags[3]],          //addborder
                                   [NSNumber numberWithBool:gameFlags[4]],          //lowgravity
                                   [NSNumber numberWithBool:gameFlags[5]],          //lasersight
                                   [NSNumber numberWithBool:gameFlags[6]],          //invulnerable
                                   [NSNumber numberWithBool:gameFlags[7]],          //resethealth
                                   [NSNumber numberWithBool:gameFlags[8]],          //vampirism
                                   [NSNumber numberWithBool:gameFlags[9]],          //karma
                                   [NSNumber numberWithBool:gameFlags[10]],         //artillery
                                   [NSNumber numberWithBool:gameFlags[11]],         //randomorder
                                   [NSNumber numberWithBool:gameFlags[12]],         //king
                                   [NSNumber numberWithBool:gameFlags[13]],         //placehedgehogs
                                   [NSNumber numberWithBool:gameFlags[14]],         //clansharesammo
                                   [NSNumber numberWithBool:gameFlags[15]],         //disablegirders
                                   [NSNumber numberWithBool:gameFlags[16]],         //disablelandobjects
                                   [NSNumber numberWithBool:gameFlags[17]],         //aisurvival
                                   [NSNumber numberWithBool:gameFlags[18]],         //infattack
                                   [NSNumber numberWithBool:gameFlags[19]],         //resetweaps
                                   [NSNumber numberWithBool:gameFlags[20]],         //perhogammo
                                   [NSNumber numberWithBool:gameFlags[21]],         //nowind
                                   [NSNumber numberWithBool:gameFlags[22]],         //morewind
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
