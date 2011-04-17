/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 10/01/2010.
 */


#import <Foundation/Foundation.h>
#import "SDL_net.h"

@interface EngineProtocolNetwork : NSObject {
    NSMutableArray *statsArray;
    NSString *savePath;
    NSDictionary *gameConfig;

    NSInteger ipcPort;              // Port on which engine will listen
    TCPsocket csd;                  // Client socket descriptor
}

@property (nonatomic,retain) NSMutableArray *statsArray;
@property (nonatomic,retain) NSString *savePath;
@property (nonatomic,retain) NSDictionary *gameConfig;
@property (assign) NSInteger ipcPort;
@property (assign) TCPsocket csd;


-(id)   init;
-(void) engineProtocol;
-(void) spawnThreadOnPort:(NSInteger) port;
-(int)  sendToEngine:(NSString *)string;
-(int)  sendToEngineNoSave:(NSString *)string;
-(void) provideTeamData:(NSString *)teamName forHogs:(NSInteger) numberOfPlayingHogs withHealth:(NSInteger) initialHealth ofColor:(NSNumber *)teamColor;
-(void) provideAmmoData:(NSString *)ammostoreName forPlayingTeams:(NSInteger) numberOfTeams;
-(NSInteger) provideScheme:(NSString *)schemeName;

@end
