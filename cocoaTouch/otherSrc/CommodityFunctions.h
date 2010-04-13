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

#define TEAMS_DIRECTORY()       [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) \
                                 objectAtIndex:0] stringByAppendingString:@"/Teams/"]

#define VOICES_DIRECTORY()	[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Sounds/voices/"]
#define GRAPHICS_DIRECTORY()    [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/"]
#define HATS_DIRECTORY()        [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hats/"]
#define FLAGS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Flags/"
#define GRAVES_DIRECTORY()      [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Graves/"]
#define FORTS_DIRECTORY()       [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Forts/"]

void createTeamNamed (NSString *nameWithoutExt);
UIImage *mergeHogHatSprites (UIImage *firstImage, UIImage *secondImage);
BOOL rotationManager (UIInterfaceOrientation interfaceOrientation);

