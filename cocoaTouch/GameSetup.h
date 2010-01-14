//
//  gameSetup.h
//  hwengine
//
//  Created by Vittorio on 10/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GameSetup : NSObject {
	NSString *localeString;
	NSDictionary *systemSettings;
	BOOL engineProtocolStarted;
}


@property (nonatomic, retain) NSString *localeString;
@property (retain) NSDictionary *systemSettings;

-(void) setArgsForLocalPlay;
-(void) engineProtocol;
-(void) startThread: (NSString *)selector;

@end

