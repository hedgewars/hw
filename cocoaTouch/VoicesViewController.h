//
//  HogHatViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDL_mixer.h"


@interface VoicesViewController : UITableViewController {
    NSMutableDictionary *teamDictionary;
    
    NSArray *voiceArray;
    NSIndexPath *lastIndexPath;

    Mix_Chunk *voiceBeingPlayed;
}

@property (nonatomic,retain) NSMutableDictionary *teamDictionary;
@property (nonatomic,retain) NSArray *voiceArray;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;

@end
