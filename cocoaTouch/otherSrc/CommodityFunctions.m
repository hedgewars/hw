//
//  CommodityFunctions.m
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CommodityFunctions.h"


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
        NSDictionary *hog = [[NSDictionary alloc] initWithObjectsAndKeys:@"100",@"health", @"0",@"level",
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
    NSLog(@"%@",teamFile);
    [theTeam writeToFile:teamFile atomically:YES];
    [teamFile release];
    [theTeam release];
}
