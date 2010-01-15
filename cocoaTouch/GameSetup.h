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
	NSString *localeString;
	NSDictionary *systemSettings;
	
	BOOL engineProtocolStarted;
	NSInteger ipcPort;
	TCPsocket sd, csd; // Socket descriptor, Client socket descriptor

}


@property (nonatomic, retain) NSString *localeString;
@property (retain) NSDictionary *systemSettings;

-(void) setArgsForLocalPlay;
-(void) engineProtocol;
-(void) startThread: (NSString *)selector;
-(void) loadSettingsFromFile:(NSString *)fileName forKey:(NSString *)objName;
-(int) sendToEngine: (NSString *)string;
-(void) unloadSettings;
@end

