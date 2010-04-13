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
    NSDictionary *teamDictionary;
    
    NSArray *voiceArray;
    NSIndexPath *lastIndexPath;

    Mix_Music *musicBeingPlayed;
}

@property (nonatomic,retain) NSDictionary *teamDictionary;
@property (nonatomic,retain) NSArray *voiceArray;
@property (nonatomic,retain) NSIndexPath *lastIndexPath;
@property (nonatomic,retain) Mix_Music *musicBeingPlayed;

@end
