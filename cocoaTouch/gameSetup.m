//
//  gameSetup.m
//  hwengine
//
//  Created by Vittorio on 10/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <pthread.h>
#import "SDL_uikitappdelegate.h"
#import "gameSetup.h"
#import "SDL_net.h"
#import "PascalImports.h"

#define IPC_PORT 51342
#define IPC_PORT_STR "51342"
#define BUFFER_SIZE 256


@implementation gameSetup

void engineProtocolThread () {
	TCPsocket sd, csd; /* Socket descriptor, Client socket descriptor */
	IPaddress ip;
	int idx, eProto;
	BOOL serverQuit, clientQuit;
	char buffer[BUFFER_SIZE], string[BUFFER_SIZE];
	Uint8 msgSize;
	Uint16 gameTicks;
	
	if (SDLNet_Init() < 0) {
		fprintf(stderr, "SDLNet_Init: %s\n", SDLNet_GetError());
		exit(EXIT_FAILURE);
	}
	
	/* Resolving the host using NULL make network interface to listen */
	if (SDLNet_ResolveHost(&ip, NULL, IPC_PORT) < 0) {
		fprintf(stderr, "SDLNet_ResolveHost: %s\n", SDLNet_GetError());
		exit(EXIT_FAILURE);
	}
	
	/* Open a connection with the IP provided (listen on the host's port) */
	if (!(sd = SDLNet_TCP_Open(&ip))) {
		fprintf(stderr, "SDLNet_TCP_Open: %s\n", SDLNet_GetError());
		exit(EXIT_FAILURE);
	}
	
	NSLog(@"engineProtocolThread - Waiting for a client");
	
	serverQuit = NO;
	while (!serverQuit) {
		
		/* This check the sd if there is a pending connection.
		 * If there is one, accept that, and open a new socket for communicating */
		if ((csd = SDLNet_TCP_Accept(sd))) {
			
			NSLog(@"engineProtocolThread - Client found");
			
			//first byte of the command alwayas contain the size of the command
			SDLNet_TCP_Recv(csd, &msgSize, sizeof(Uint8));
			
			SDLNet_TCP_Recv(csd, buffer, msgSize);
			gameTicks = SDLNet_Read16(&buffer[msgSize - 2]);
			NSLog(@"engineProtocolThread - %d: received [%s]", gameTicks, buffer);
			
			if ('C' == buffer[0]) {
				NSLog(@"engineProtocolThread - Client found and connected");
				clientQuit = NO;
			} else {
				NSLog(@"engineProtocolThread - wrong Connected message, closing");
				clientQuit = YES;
			}
			
			while (!clientQuit){
				/* Now we can communicate with the client using csd socket
				 * sd will remain opened waiting other connections */
				idx = 0;
				msgSize = 0;
				memset(buffer, 0, BUFFER_SIZE);
				memset(string, 0, BUFFER_SIZE);
				SDLNet_TCP_Recv(csd, &msgSize, sizeof(Uint8));
			
				SDLNet_TCP_Recv(csd, buffer, msgSize);
				gameTicks = SDLNet_Read16(&buffer[msgSize - 2]);
				NSLog(@"engineProtocolThread - %d: received [%s]", gameTicks, buffer);
				
				switch (buffer[0]) {
					case '?':
						NSLog(@"Ping? Pong!");
						string[idx++] = 0x01;
						string[idx++] = '!';
						
						SDLNet_TCP_Send(csd, string, idx);
						break;
					case 'E':
						NSLog(@"ERROR - last console line: [%s]", buffer);
						clientQuit = YES;
						break;
					default:
						sscanf(buffer, "%*s %d", &eProto);
						if (HW_protoVer() == eProto) {
							NSLog(@"Setting protocol version %s", buffer);
						} else {
							NSLog(@"ERROR - wrong protocol number: [%s] - expecting %d", buffer, eProto);
							clientQuit = YES;
						}
						
						break;
				} 
				
				/*
				 // Terminate this connection 
				 if(strcmp(buffer, "exit") == 0)	{
				 quit2 = 1;
				 printf("Terminate connection\n");
				 }
				 // Quit the thread
				 if(strcmp(buffer, "quit") == 0)	{
				 quit2 = 1;
				 quit = 1;
				 printf("Quit program\n");
				 }
				 */
			}
		}
		
		/* Close the client socket */
		SDLNet_TCP_Close(csd);
	}

	SDLNet_TCP_Close(sd);
	SDLNet_Quit();

	pthread_exit(NULL);
}

void setupArgsForLocalPlay() {
	forward_argc = 18;
	forward_argv = (char **)realloc(forward_argv, forward_argc * sizeof(char *));
	//forward_argv[i] = malloc( (strlen(argv[i])+1) * sizeof(char));
	forward_argv[ 1] = forward_argv[0];	// (UNUSED)
	forward_argv[ 2] = "320";			// cScreenWidth (NO EFFECT)
	forward_argv[ 3] = "480";			// cScreenHeight (NO EFFECT)
	forward_argv[ 4] = "32";			// cBitsStr
	forward_argv[ 5] = IPC_PORT_STR;	// ipcPort; <- (MAIN TODO)
	forward_argv[ 6] = "1";				// cFullScreen (NO EFFECT)
	forward_argv[ 7] = "0";				// isSoundEnabled (TOSET)
	forward_argv[ 8] = "1";				// cVSyncInUse (UNUSED)
	forward_argv[ 9] = "en.txt";		// cLocaleFName (TOSET)
	forward_argv[10] = "100";			// cInitVolume (TOSET)
	forward_argv[11] = "8";				// cTimerInterval
	forward_argv[12] = "Data";			// PathPrefix
	forward_argv[13] = "1";				// cShowFPS (TOSET?)
	forward_argv[14] = "0";				// cAltDamage (TOSET)
	forward_argv[15] = "Koda";			// UserNick (DecodeBase64(ParamStr(15)) FTW) <- TODO
	forward_argv[16] = "0";				// isMusicEnabled (TOSET)
	forward_argv[17] = "0";				// cReducedQuality

	return;
}

@end
