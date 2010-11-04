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


#import "CommodityFunctions.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <QuartzCore/QuartzCore.h>
#import "AudioToolbox/AudioToolbox.h"
#import "PascalImports.h"

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
        NSDictionary *hog = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt:0],@"level",
                             hogName,@"hogname", @"NoHat",@"hat", nil];
        [hogName release];
        [hedgehogs addObject:hog];
        [hog release];
    }

    NSDictionary *theTeam = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"hash",
                             @"Statue",@"grave", @"Plane",@"fort", @"Default",@"voicepack",
                             @"hedgewars",@"flag", hedgehogs,@"hedgehogs", nil];
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
                         @"9391929422199121032235111001201000000211110101010",@"ammostore_initialqt",
                         @"0405040541600655546554464776576666666155510101110",@"ammostore_probability",
                         @"0000000000000205500000040007004000000000200000000",@"ammostore_delay",
                         @"1311110312111111123114111111111111111211111101110",@"ammostore_crate", nil];
            break;
        case 1: //crazy
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"9999999999999999992999999999999999299999999909990",@"ammostore_initialqt",
                         @"1111110111111111111111111111111111111111111101110",@"ammostore_probability",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"1311110312111111123114111111111111111211110101110",@"ammostore_crate", nil];
            break;
        case 2: //pro mode
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"9090009000000000000009000000000000000000000000000",@"ammostore_initialqt",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"0000000000000205500000040007004000000000200000000",@"ammostore_delay",
                         @"1111111111111111111111111111111111111111100101110",@"ammostore_crate", nil];
            break;
        case 3: //shoppa
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"0000009900000000000000000000000000000000000000000",@"ammostore_initialqt",
                         @"4444410044244402210112121222422000000002000400010",@"ammostore_probability",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"1111111111111111111111111111111111111111101101110",@"ammostore_crate", nil];
            break;
        case 4: //basketball
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"9391929422199121032235111001201000000211110101000",@"ammostore_initialqt",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"0000000000000005500000040007004000000000200000000",@"ammostore_delay",
                         @"1111111111111111111111111111111111111111111101110",@"ammostore_crate", nil];
            break;
        case 5: //minefield
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"0000009900090000000300000000000000000000000000000",@"ammostore_initialqt",
                         @"0000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"0000000000000205500000040007004000000000200000000",@"ammostore_delay",
                         @"1111111111111111111111111111111111111111111101110",@"ammostore_crate", nil];
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
                                   [NSNumber numberWithInt:100],      //damagemodifier
                                   [NSNumber numberWithInt:45],       //turntime
                                   [NSNumber numberWithInt:100],      //initialhealth
                                   [NSNumber numberWithInt:15],       //suddendeathtimeout
                                   [NSNumber numberWithInt:5],        //cratedrops
                                   [NSNumber numberWithInt:3],        //minestime
                                   [NSNumber numberWithInt:4],        //mines
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

BOOL inline rotationManager (UIInterfaceOrientation interfaceOrientation) {
    if (IS_IPAD())
        return (interfaceOrientation == UIInterfaceOrientationLandscapeRight) ||
               (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
    else
        return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

NSInteger inline randomPort () {
    srandom(time(NULL));
    NSInteger res = (random() % 64511) + 1024;
    return (res == DEFAULT_NETGAME_PORT) ? randomPort() : res;
}

void popError (const char *title, const char *message) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithUTF8String:title]
                                                    message:[NSString stringWithUTF8String:message]
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

// by http://landonf.bikemonkey.org/code/iphone/Determining_Available_Memory.20081203.html
void print_free_memory () {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);

    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        DLog(@"Failed to fetch vm statistics");

    /* Stats in bytes */
    natural_t mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    DLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);
}

BOOL inline isApplePhone () {
    return (IS_IPAD() == NO);
}

NSString *modelType () {
    size_t size;
    // set 'oldp' parameter to NULL to get the size of the data returned so we can allocate appropriate amount of space
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = (char *)malloc(sizeof(char) * size);
    // get the platform name
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *modelId = [NSString stringWithUTF8String:name];
    free(name);

    return modelId;
}

void playSound (NSString *snd) {
    //Get the filename of the sound file:
    NSString *path = [NSString stringWithFormat:@"%@/%@.wav",[[NSBundle mainBundle] resourcePath],snd];
    
    //declare a system sound id
    SystemSoundID soundID;

    //Get a URL for the sound file
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];

    //Use audio sevices to create the sound
    AudioServicesCreateSystemSoundID((CFURLRef)filePath, &soundID);

    //Use audio services to play the sound
    AudioServicesPlaySystemSound(soundID);
}

NSArray inline *getAvailableColors (void) {
    return [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:0x4376e9],     // bluette
                                     [NSNumber numberWithUnsignedInt:0x3e9321],     // greeeen
                                     [NSNumber numberWithUnsignedInt:0xa23dbb],     // violett
                                     [NSNumber numberWithUnsignedInt:0xff9329],     // oranngy
                                     [NSNumber numberWithUnsignedInt:0xdd0000],     // reddish
                                     [NSNumber numberWithUnsignedInt:0x737373],     // graaaay
                                     [NSNumber numberWithUnsignedInt:0xbba23d],     // gold$$$
                                     [NSNumber numberWithUnsignedInt:0x3da2bb],     // cyannnn  
                                     nil];
}

UILabel *createBlueLabel (NSString *title, CGRect frame) {
    return createLabelWithParams(title, frame, 1.5f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_DARKBLUE);
}

UILabel *createLabelWithParams (NSString *title, CGRect frame, CGFloat borderWidth, UIColor *borderColor, UIColor *backgroundColor) {
    UILabel *theLabel = [[UILabel alloc] initWithFrame:frame];
    theLabel.backgroundColor = backgroundColor;

    if (title != nil) {
        theLabel.text = title;
        theLabel.textColor = UICOLOR_HW_YELLOW_TEXT;
        theLabel.textAlignment = UITextAlignmentCenter;
        theLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]*80/100];
    }
    
    [theLabel.layer setBorderWidth:borderWidth];
    [theLabel.layer setBorderColor:borderColor.CGColor];
    [theLabel.layer setCornerRadius:8.0f];
    [theLabel.layer setMasksToBounds:YES];
    
    return theLabel;
}
