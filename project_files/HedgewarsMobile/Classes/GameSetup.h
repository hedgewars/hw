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
    NSDictionary *gameConfig;

    NSInteger ipcPort;  // Port on which engine will listen
    TCPsocket csd;      // Client socket descriptor
}

@property (nonatomic, retain) NSDictionary *systemSettings;
@property (nonatomic, retain) NSDictionary *gameConfig;

-(id) initWithDictionary:(NSDictionary *)gameDictionary;
-(void) engineProtocol;
-(void) startThread:(NSString *)selector;
-(int)  sendToEngine:(NSString *)string;
-(void) provideTeamData:(NSString *)teamName forHogs:(NSInteger) numberOfPlayingHogs withHealth:(NSInteger) initialHealth ofColor:(NSNumber *)teamColor;
-(void) provideAmmoData:(NSString *)ammostoreName forPlayingTeams:(NSInteger) numberOfTeams;
-(NSInteger) provideScheme:(NSString *)schemeName;

-(const char **)getSettings;

@end
