//
//  gameSetup.h
//  hwengine
//
//  Created by Vittorio on 10/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GameSetup : NSObject {
	NSLocale *locale;
	BOOL engineProtocolStarted;
}


@property (nonatomic, retain) NSLocale *locale;
@property (nonatomic) BOOL engineProtocolStarted;

-(void) setArgsForLocalPlay;
-(void) engineProtocol;
-(void) startThread: (NSString *)selector;

@end

