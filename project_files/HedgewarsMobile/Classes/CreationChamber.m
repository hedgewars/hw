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
            theWeapon = [[NSDictionary alloc] initWithObjects:
                         [NSArray arrayWithObjects:
                          @"93919294221991210322351110012010000002111101010111200",
                          @"04050405416006555465544647765766666661555101011154100",
                          @"00000000000002055000000400070040000000002000000006000",
                          @"13111103121111111231141111111111111112111111011111200",
                          nil]
                                                      forKeys: [NSArray arrayWithObjects:
                                                                @"ammostore_initialqt",
                                                                @"ammostore_probability",
                                                                @"ammostore_delay",
                                                                @"ammostore_crate", nil]];
            break;
        case 1: //crazy
            theWeapon = [[NSDictionary alloc] initWithObjects:
                         [NSArray arrayWithObjects:
                          @"99999999999999999929999999999999992999999999099999900",
                          @"11111101111111111111111111111111111111111111011111100",
                          @"00000000000000000000000000000000000000000000000000000",
                          @"13111103121111111231141111111111111112111101011111100",
                          nil]
                                                      forKeys: [NSArray arrayWithObjects:
                                                                @"ammostore_initialqt",
                                                                @"ammostore_probability",
                                                                @"ammostore_delay",
                                                                @"ammostore_crate", nil]];
            break;
        case 2: //pro mode
            theWeapon = [[NSDictionary alloc] initWithObjects:
                         [NSArray arrayWithObjects:
                          @"90900090000000000000090000000000000000000000000000000",
                          @"00000000000000000000000000000000000000000000000000000",
                          @"00000000000002055000000400070040000000002000000000000",
                          @"11111111111111111111111111111111111111111001011111100",
                          nil]
                                                      forKeys: [NSArray arrayWithObjects:
                                                                @"ammostore_initialqt",
                                                                @"ammostore_probability",
                                                                @"ammostore_delay",
                                                                @"ammostore_crate", nil]];
            break;
        case 3: //shoppa
            theWeapon = [[NSDictionary alloc] initWithObjects:
                         [NSArray arrayWithObjects:
                          @"00000099000000000000000000000000000000000000000000000",
                          @"44444100442444022101121212224220000000020004000100100",
                          @"00000000000000000000000000000000000000000000000000000",
                          @"11111111111111111111111111111111111111111011011111100",
                          nil]
                                                      forKeys: [NSArray arrayWithObjects:
                                                                @"ammostore_initialqt",
                                                                @"ammostore_probability",
                                                                @"ammostore_delay",
                                                                @"ammostore_crate", nil]];
            break;
        case 4: //clean slate
            theWeapon = [[NSDictionary alloc] initWithObjects:
                         [NSArray arrayWithObjects:
                          @"10100090000100000110000000000000000000000000000010000",
                          @"04050405416006555465544647765766666661555101011154100",
                          @"00000000000000000000000000000000000000000000000000000",
                          @"13111103121111111231141111111111111112111111011111100",
                          nil]
                                                      forKeys: [NSArray arrayWithObjects:
                                                                @"ammostore_initialqt",
                                                                @"ammostore_probability",
                                                                @"ammostore_delay",
                                                                @"ammostore_crate", nil]];
            break;
        case 5: //minefield
            theWeapon = [[NSDictionary alloc] initWithObjects:
                         [NSArray arrayWithObjects:
                          @"00000099000900000003000000000000000000000000000000000",
                          @"00000000000000000000000000000000000000000000000000000",
                          @"00000000000002055000000400070040000000002000000006000",
                          @"11111111111111111111111111111111111111111111011111100",
                          nil]
                                                      forKeys: [NSArray arrayWithObjects:
                                                                @"ammostore_initialqt",
                                                                @"ammostore_probability",
                                                                @"ammostore_delay",
                                                                @"ammostore_crate", nil]];
            break;
        case 6: //thinking with portals
            theWeapon = [[NSDictionary alloc] initWithObjects:
                         [NSArray arrayWithObjects:
                          @"90000090020000000021000000000000001100000900000000000",
                          @"04050405416006555465544647765766666661555101011154100",
                          @"00000000000002055000000400070040000000002000000006000",
                          @"13111103121111111231141111111111111112111111011111100",
                          nil]
                                                      forKeys: [NSArray arrayWithObjects:
                                                                @"ammostore_initialqt",
                                                                @"ammostore_probability",
                                                                @"ammostore_delay",
                                                                @"ammostore_crate", nil]];
            break;
    }

    NSString *weaponFile = [[NSString alloc] initWithFormat:@"%@/%@.plist", weaponsDirectory, nameWithoutExt];

    [theWeapon writeToFile:weaponFile atomically:YES];
    [weaponFile release];
    [theWeapon release];
}

void createSchemeNamed (NSString *nameWithoutExt) {
    NSString *schemesDirectory = SCHEMES_DIRECTORY();
    NSString *path = nil;

    if (![[NSFileManager defaultManager] fileExistsAtPath: schemesDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:schemesDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }

    // load data to get the size of the arrays and their default values
    path = [NSString stringWithFormat:@"%@/basicFlags_en.plist",IFRONTEND_DIRECTORY()];
    NSArray *basicSettings = [[NSArray alloc] initWithContentsOfFile:path];
    NSMutableArray *basicArray  = [[NSMutableArray alloc] initWithCapacity:[basicSettings count]];
    for (NSDictionary *basicDict in basicSettings)
        [basicArray addObject:[basicDict objectForKey:@"default"]];
    [basicSettings release];

    path = [NSString stringWithFormat:@"%@/gameFlags_en.plist",IFRONTEND_DIRECTORY()];
    NSArray *mods = [[NSArray alloc] initWithContentsOfFile:path];
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
