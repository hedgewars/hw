//
//  gameSetup.m
//  hwengine
//
//  Created by Vittorio on 10/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameSetup.h"
#import "SDL_uikitappdelegate.h"
#import "SDL_net.h"
#import "PascalImports.h"

#define BUFFER_SIZE 256

@implementation GameSetup

@synthesize localeString, systemSettings;

-(id) init {
	self = [super init];
	self.localeString = [[[NSLocale currentLocale] localeIdentifier] stringByAppendingString:@".txt"];
	self.systemSettings = nil;
	engineProtocolStarted = NO;
	ipcPort = 51432;
	return self;
}

-(void) dealloc {
	if (systemSettings) [self.systemSettings release];
	[self.localeString autorelease];
	[super dealloc];
}

#pragma mark -
#pragma mark Thread/Network relevant code
-(void) startThread: (NSString *) selector {
	SEL usage = NSSelectorFromString(selector);
	
	// do not start the server thread because the port is already bound
	if (NO == engineProtocolStarted) {
		engineProtocolStarted = YES;
		[NSThread detachNewThreadSelector:usage toTarget:self withObject:nil];
	}
}

-(int) sendToEngine: (NSString *)string {
	Uint8 length = [string length];
	
	SDLNet_TCP_Send(csd, &length , 1);
	return SDLNet_TCP_Send(csd, [string UTF8String], length);
}

-(void) engineProtocol {
	IPaddress ip;
	int idx, eProto;
	BOOL serverQuit, clientQuit;
	char buffer[BUFFER_SIZE], string[BUFFER_SIZE];
	Uint8 msgSize;
	Uint16 gameTicks;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (SDLNet_Init() < 0) {
		fprintf(stderr, "SDLNet_Init: %s\n", SDLNet_GetError());
		exit(EXIT_FAILURE);
	}
	
	/* Resolving the host using NULL make network interface to listen */
	if (SDLNet_ResolveHost(&ip, NULL, ipcPort) < 0) {
		fprintf(stderr, "SDLNet_ResolveHost: %s\n", SDLNet_GetError());
		exit(EXIT_FAILURE);
	}
	
	/* Open a connection with the IP provided (listen on the host's port) */
	if (!(sd = SDLNet_TCP_Open(&ip))) {
		fprintf(stderr, "SDLNet_TCP_Open: %s\n", SDLNet_GetError());
		exit(EXIT_FAILURE);
	}
	
	NSLog(@"engineProtocol - Waiting for a client");
	
	serverQuit = NO;
	while (!serverQuit) {
		
		/* This check the sd if there is a pending connection.
		 * If there is one, accept that, and open a new socket for communicating */
		csd = SDLNet_TCP_Accept(sd);
		if (NULL != csd) {
			
			NSLog(@"engineProtocol - Client found");
			
			//first byte of the command alwayas contain the size of the command
			SDLNet_TCP_Recv(csd, &msgSize, sizeof(Uint8));
			
			SDLNet_TCP_Recv(csd, buffer, msgSize);
			gameTicks = SDLNet_Read16(&buffer[msgSize - 2]);
			//NSLog(@"engineProtocol - %d: received [%s]", gameTicks, buffer);
			
			if ('C' == buffer[0]) {
				NSLog(@"engineProtocol - sending game config");
				
				// send config data data
				/*seed is arbitrary string
				[16:12] unC0Rr:
				addteam <color> <team name>
				[16:13] unC0Rr:
				addhh <level> <health> <hedgehog name>
				[16:13] unC0Rr:
				<level> is 0 for human, 1-5 for bots (5 is the most stupid)*/				// local game
				[self sendToEngine:@"TL"];
				
				// seed info
				[self sendToEngine:@"eseed {232c1b42-7d39-4ee6-adf8-4240e1f1efb8}"];
				
				// various flags
				[self sendToEngine:@"e$gmflags 256"]; 

				// various flags
				[self sendToEngine:@"e$damagepct 100"];
				
				// various flags
				[self sendToEngine:@"e$turntime 45000"];
				
				// various flags
				[self sendToEngine:@"e$minestime 3000"];
				
				// various flags
				[self sendToEngine:@"e$landadds 4"];
				
				// various flags
				[self sendToEngine:@"e$sd_turns 15"];
												
				// various flags
				[self sendToEngine:@"e$casefreq 5"];
				
				// dimension of the map
				[self sendToEngine:@"e$template_filter 1"];
								
				// theme info
				[self sendToEngine:@"etheme Freeway"];
				
				// team 1 info
				[self sendToEngine:@"eaddteam 4421353 System Cats"];
				
				// team 1 grave info
				[self sendToEngine:@"egrave star"];
				
				// team 1 fort info
				[self sendToEngine:@"efort  Earth"];
								
				// team 1 voicepack info
				[self sendToEngine:@"evoicepack Classic"];
				
				// team 1 binds (skipped)			
				// team 1 members info
				[self sendToEngine:@"eaddhh 0 100 Snow Leopard"];
				[self sendToEngine:@"ehat NoHat"];
				
				// team 1 ammostore
				[self sendToEngine:@"eammstore 93919294221991210322351110012010000002110404000441400444645644444774776112211144"];

				// team 2 info
				[self sendToEngine:@"eaddteam 4100897 Poke-MAN"];
				
				// team 2 grave info
				[self sendToEngine:@"egrave Badger"];
				
				// team 2 fort info
				[self sendToEngine:@"efort UFO"];
				
				// team 2 voicepack info
				[self sendToEngine:@"evoicepack Classic"];
				
				// team 2 binds (skipped)
				// team 2 members info
				[self sendToEngine:@"eaddhh 0 100 Raichu"];
				[self sendToEngine:@"ehat Bunny"];
				
				// team 2 ammostore
				[self sendToEngine:@"eammstore 93919294221991210322351110012010000002110404000441400444645644444774776112211144"];
				
				clientQuit = NO;
			} else {
				NSLog(@"engineProtocolThread - wrong message or client closed connection");
				clientQuit = YES;
			}
			
			while (!clientQuit){
				/* Now we can communicate with the client using csd socket
				 * sd will remain opened waiting other connections */
				idx = 0;
				msgSize = 0;
				memset(buffer, 0, BUFFER_SIZE);
				memset(string, 0, BUFFER_SIZE);
				if (SDLNet_TCP_Recv(csd, &msgSize, sizeof(Uint8)) <= 0)
					clientQuit = YES;
				if (SDLNet_TCP_Recv(csd, buffer, msgSize) <=0)
					clientQuit = YES;
				
				gameTicks = SDLNet_Read16(&buffer[msgSize - 2]);
				//NSLog(@"engineProtocolThread - %d: received [%s]", gameTicks, buffer);
				
				switch (buffer[0]) {
					case '?':
						NSLog(@"Ping? Pong!");
						[self sendToEngine:@"!"];
						break;
					case 'E':
						NSLog(@"ERROR - last console line: [%s]", buffer);
						clientQuit = YES;
						break;
					case 'e':
						sscanf(buffer, "%*s %d", &eProto);
						if (HW_protoVer() == eProto) {
							NSLog(@"Setting protocol version %s", buffer);
						} else {
							NSLog(@"ERROR - wrong protocol number: [%s] - expecting %d", buffer, eProto);
							clientQuit = YES;
						}
						break;
					case 'i':
						switch (buffer[1]) {
							case 'r':
								NSLog(@"Winning team: %s", &buffer[2]);
								break;
							case 'k':
								NSLog(@"Best Hedgehog: %s", &buffer[2]);
								break;
						}
						break;
					default:
						// empty packet or just statistics
						break;
					// missing case for exiting right away
				}
			}
			NSLog(@"Client Exited");
			// wait a little to let the client close cleanly
			sleep(5);
			// Close the client socket
			SDLNet_TCP_Close(csd);
		}

	}

	SDLNet_TCP_Close(sd);
	SDLNet_Quit();

	[pool release];
	[NSThread exit];
}

#pragma mark -
#pragma mark Settings setup methods
-(void) loadSettingsFromFile:(NSString *)fileName forKey:(NSString *)objName {
	NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:fileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {	
		NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
		[self setValue:dict forKey:objName];
		[dict release];
	} else {
		//TODO create it
		[NSException raise:@"File NOT found" format:@"The file %@ was not found at %@", fileName, filePath];
	}

}

-(void) unloadSettings {
	[systemSettings release];
}


@end
