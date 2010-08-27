//
//  CommodityFunctions.m
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CommodityFunctions.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

void createTeamNamed (NSString *nameWithoutExt) {
    NSString *teamsDirectory = TEAMS_DIRECTORY();

    if (![[NSFileManager defaultManager] fileExistsAtPath: teamsDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:teamsDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }

    NSMutableArray *hedgehogs = [[NSMutableArray alloc] initWithCapacity: MAX_HOGS];

    for (int i = 0; i < MAX_HOGS; i++) {
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
                         [NSNumber numberWithInt:CURRENT_AMMOSIZE],@"version",
                         @"939192942219912103223511100120100000021111011101",@"ammostore_initialqt",
                         @"040504054160065554655446477657666666615551011111",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000",@"ammostore_delay",
                         @"131111031211111112311411111111111111121111111111",@"ammostore_crate", nil];
            break;
        case 1: //crazy
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:CURRENT_AMMOSIZE],@"version",
                         @"999999999999999999299999999999999929999999999999",@"ammostore_initialqt",
                         @"111111011111111111111111111111111111111111111111",@"ammostore_probability",
                         @"000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"131111031211111112311411111111111111121111010111",@"ammostore_crate", nil];
            break;
        case 2: //pro mode
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:CURRENT_AMMOSIZE],@"version",
                         @"909000900000000000000900000000000000000000090000",@"ammostore_initialqt",
                         @"000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000",@"ammostore_delay",
                         @"111111111111111111111111111111111111111110011111",@"ammostore_crate", nil];
            break;
        case 3: //shoppa
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:CURRENT_AMMOSIZE],@"version",
                         @"000000990000000000000000000000000000000000000000",@"ammostore_initialqt",
                         @"444441004424440221011212122242200000000200040001",@"ammostore_probability",
                         @"000000000000000000000000000000000000000000000000",@"ammostore_delay",
                         @"111111111111111111111111111111111111111110111111",@"ammostore_crate", nil];
            break;
        case 4: //basketball
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:CURRENT_AMMOSIZE],@"version",
                         @"939192942219912103223511100120100000021111011100",@"ammostore_initialqt",
                         @"000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"000000000000000550000004000700400000000020000000",@"ammostore_delay",
                         @"111111111111111111111111111111111111111111111111",@"ammostore_crate", nil];
            break;
        case 5: //minefield
            theWeapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:CURRENT_AMMOSIZE],@"version",
                         @"000000990009000000030000000000000000000000000000",@"ammostore_initialqt",
                         @"000000000000000000000000000000000000000000000000",@"ammostore_probability",
                         @"000000000000020550000004000700400000000020000000",@"ammostore_delay",
                         @"111111111111111111111111111111111111111111111111",@"ammostore_crate", nil];
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

    NSArray *theScheme = [[NSArray alloc] initWithObjects:
                          [NSNumber numberWithBool:NO],    //fortmode
                          [NSNumber numberWithBool:NO],    //divideteam
                          [NSNumber numberWithBool:NO],    //solidland
                          [NSNumber numberWithBool:NO],    //addborder
                          [NSNumber numberWithBool:NO],    //lowgravity
                          [NSNumber numberWithBool:NO],    //lasersight
                          [NSNumber numberWithBool:NO],    //invulnerable
                          [NSNumber numberWithBool:YES],   //addmines
                          [NSNumber numberWithBool:NO],    //vampirism
                          [NSNumber numberWithBool:NO],    //karma
                          [NSNumber numberWithBool:NO],    //artillery
                          [NSNumber numberWithBool:YES],   //randomorder
                          [NSNumber numberWithBool:NO],    //king
                          [NSNumber numberWithBool:NO],    //placehedgehogs
                          [NSNumber numberWithBool:NO],    //clansharesammo
                          [NSNumber numberWithBool:NO],    //disablegirders
                          [NSNumber numberWithBool:NO],    //disablelandobjects
                          [NSNumber numberWithInt:100],    //damagemodifier
                          [NSNumber numberWithInt:45],     //turntime
                          [NSNumber numberWithInt:100],    //initialhealth
                          [NSNumber numberWithInt:15],     //suddendeathtimeout
                          [NSNumber numberWithInt:5],      //cratedrops
                          [NSNumber numberWithInt:3],      //minestime
                          [NSNumber numberWithInt:4],      //mines
                          [NSNumber numberWithInt:0],      //dudmines
                          [NSNumber numberWithInt:2],      //explosives
                          nil];

    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@.plist", schemesDirectory, nameWithoutExt];

    [theScheme writeToFile:schemeFile atomically:YES];
    [schemeFile release];
    [theScheme release];
}

BOOL rotationManager (UIInterfaceOrientation interfaceOrientation) {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight) ||
           (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

NSInteger randomPort () {
    srandom(time(NULL));
    return (random() % 64511) + 1024;
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

BOOL isPhone () {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
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
