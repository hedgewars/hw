//
//  CommodityFunctions.m
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CommodityFunctions.h"
#import "SDL_uikitappdelegate.h"

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
    
    NSDictionary *theTeam = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"hash", nameWithoutExt,@"teamname",
                             @"Statue",@"grave", @"Plane",@"fort", @"Default",@"voicepack",
                             @"hedgewars",@"flag", hedgehogs,@"hedgehogs", nil];
    [hedgehogs release];
    
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist", teamsDirectory, nameWithoutExt];

    [theTeam writeToFile:teamFile atomically:YES];
    [teamFile release];
    [theTeam release];
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
                          [NSNumber numberWithBool:NO],    //addmines
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);

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
    


