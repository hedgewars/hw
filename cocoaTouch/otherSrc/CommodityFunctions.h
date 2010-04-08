//
//  CommodityFunctions.h
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_HOGS 8

#define TEAMS_DIRECTORY()   [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                             objectAtIndex:0] stringByAppendingString:@"/Teams/"]
#define HATS_DIRECTORY()    [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hats/"]
#define FLAGS_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Flags/"]
#define FORTS_DIRECTORY()   [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Forts/"]

void createTeamNamed (NSString *nameWithoutExt);
