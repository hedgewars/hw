//
//  gameSetup.h
//  hwengine
//
//  Created by Vittorio on 10/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDL_net.h"

@interface GameSetup : NSObject {
	NSDictionary *systemSettings;
	NSArray *teams;
    
	NSInteger ipcPort;
	TCPsocket sd, csd; // Socket descriptor, Client socket descriptor
}

@property (nonatomic, retain) NSDictionary *systemSettings;
@property (nonatomic, retain) NSArray *teams;

-(void) engineProtocol;
-(void) startThread: (NSString *)selector;
-(int) sendToEngine: (NSString *)string;
-(void) sendTeamData:(NSDictionary *)teamData;
-(const char **)getSettings;
@end

