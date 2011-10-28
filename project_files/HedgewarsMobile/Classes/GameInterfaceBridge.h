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
 * File created on 18/04/2011.
 */


#import <Foundation/Foundation.h>
#import "EngineProtocolNetwork.h"

typedef enum {gtNone, gtLocal, gtSave, gtMission, gtNet} TGameType;
typedef enum {gsNone, gsInGame, gsEnded, gsInterrupted} TGameStatus;

@class OverlayViewController;

@interface GameInterfaceBridge : NSObject <EngineProtocolDelegate> {
    UIViewController *parentController;
    OverlayViewController *overlayController;

    NSString *savePath;
    EngineProtocolNetwork *engineProtocol;

    NSInteger ipcPort;  // Port on which engine will listen
    TGameType gameType;
}

@property (assign) UIViewController *parentController;
@property (nonatomic,retain) NSString *savePath;

@property (nonatomic,retain) OverlayViewController *overlayController;
@property (nonatomic,retain) EngineProtocolNetwork *engineProtocol;

@property (assign) NSInteger ipcPort;
@property (assign) TGameType gameType;


-(id)   initWithController:(id) viewController;
-(void) startLocalGame:(NSDictionary *)withOptions;
-(void) startSaveGame:(NSString *)atPath;
-(void) startMissionGame:(NSString *)withScript;

-(void) prepareEngineLaunch;
-(void) engineLaunch;
-(void) gameHasEndedWithStats:(NSArray *)stats;

@end
