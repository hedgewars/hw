/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import "ServerProtocolNetwork.h"
#import "hwconsts.h"

#define BUFFER_SIZE 256

static ServerProtocolNetwork *serverConnection;

@implementation ServerProtocolNetwork
@synthesize serverPort, serverAddress, ssd;

#pragma mark -
#pragma mark init and class methods
-(id) init:(NSInteger) onPort withAddress:(NSString *)address {
    if ((self = [super init])) {
        self.serverPort = onPort;
        self.serverAddress = address;
    }
    serverConnection = self;
    return self;
}

-(id) init {
    return [self init:NETGAME_DEFAULT_PORT withAddress:@"netserver.hedgewars.org"];
}

-(id) initOnPort:(NSInteger) port {
    return [self init:port withAddress:@"netserver.hedgewars.org"];
}

-(id) initToAddress:(NSString *)address {
    return [self init:NETGAME_DEFAULT_PORT withAddress:address];
}

-(void) dealloc {
    releaseAndNil(serverAddress);
    serverConnection = nil;
    [super dealloc];
}

+(id) openServerConnection {
    id connection = [[self alloc] init];
    [NSThread detachNewThreadSelector:@selector(serverProtocol)
                             toTarget:connection
                           withObject:nil];
    [connection retain];    // retain count here is +2
    return connection;
}

#pragma mark -
#pragma mark Communication layer
-(int) sendToServer:(NSString *)command {
    NSString *message = [[NSString alloc] initWithFormat:@"%@\n\n",command];
    int result = SDLNet_TCP_Send(self.ssd, [message UTF8String], [message length]);
    [message release];
    return result;
}

-(int) sendToServer:(NSString *)command withArgument:(NSString *)argument {
    NSString *message = [[NSString alloc] initWithFormat:@"%@\n%@\n\n",command,argument];
    int result = SDLNet_TCP_Send(self.ssd, [message UTF8String], [message length]);
    [message release];
    return result;
}

-(void) serverProtocol {
    @autoreleasepool {
    
    IPaddress ip;
    BOOL clientQuit = NO;
    char *buffer = (char *)malloc(sizeof(char)*BUFFER_SIZE);
    int dim = BUFFER_SIZE;
    uint8_t msgSize;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (SDLNet_Init() < 0) {
        DLog(@"SDLNet_Init: %s", SDLNet_GetError());
        clientQuit = YES;
    }

    // Resolving the host using NULL make network interface to listen
    if (SDLNet_ResolveHost(&ip, [self.serverAddress UTF8String] , self.serverPort) < 0 && !clientQuit) {
        DLog(@"SDLNet_ResolveHost: %s", SDLNet_GetError());
        clientQuit = YES;
    }

    // Open a connection with the IP provided (listen on the host's port)
    if (!(self.ssd = SDLNet_TCP_Open(&ip)) && !clientQuit) {
        DLog(@"SDLNet_TCP_Open: %s %d", SDLNet_GetError(), self.serverPort);
        clientQuit = YES;
    }

    DLog(@"Found server on port %d", self.serverPort);
    while (!clientQuit) {
        int index = 0;
        BOOL exitBufferLoop = NO;
        memset(buffer, '\0', dim);

        while (exitBufferLoop != YES) {
            msgSize = SDLNet_TCP_Recv(self.ssd, &buffer[index], 2);

            // exit in case of error
            if (msgSize <= 0) {
                DLog(@"SDLNet_TCP_Recv: %s", SDLNet_GetError());
                clientQuit = YES;
                break;
            }

            // update index position and check for End-Of-Message
            index += msgSize;
            if (strncmp(&buffer[index-2], "\n\n", 2) == 0) {
                exitBufferLoop = YES;
            }

            // if message is too big allocate new space
            if (index >= dim) {
                dim += BUFFER_SIZE;
                buffer = (char *)realloc(buffer, dim);
                if (buffer == NULL) {
                    clientQuit = YES;
                    break;
                }
            }
        }

        NSString *bufferedMessage = [[NSString alloc] initWithBytes:buffer length:index-2 encoding:NSASCIIStringEncoding];
        NSArray *listOfCommands = [bufferedMessage componentsSeparatedByString:@"\n"];
        [bufferedMessage release];
        NSString *command = [listOfCommands objectAtIndex:0];
        DLog(@"size = %d, %@", index-2, listOfCommands);
        if ([command isEqualToString:@"PING"]) {
            if ([listOfCommands count] > 1)
                [self sendToServer:@"PONG" withArgument:[listOfCommands objectAtIndex:1]];
            else
                [self sendToServer:@"PONG"];
            DLog(@"PONG");
        }
        else if ([command isEqualToString:@"NICK"]) {
            //what is this for?
        }
        else if ([command isEqualToString:@"PROTO"]) {
            //what is this for?
        }
        else if ([command isEqualToString:@"ROOM"]) {
            //TODO: stub
        }
        else if ([command isEqualToString:@"LOBBY:LEFT"]) {
            //TODO: stub
        }
        else if ([command isEqualToString:@"LOBBY:JOINED"]) {
            //TODO: stub
        }
        else if ([command isEqualToString:@"ASKPASSWORD"]) {
            NSString *pwd = [defaults objectForKey:@"password"];
            [self sendToServer:@"PASSWORD" withArgument:pwd];
        }
        else if ([command isEqualToString:@"CONNECTED"]) {
            int netProto;
            char *versionStr;
            HW_versionInfo(&netProto, &versionStr);
            NSString *nick = [defaults objectForKey:@"username"];
            [self sendToServer:@"NICK" withArgument:nick];
            [self sendToServer:@"PROTO" withArgument:[NSString stringWithFormat:@"%d",netProto]];
        }
        else if ([command isEqualToString:@"SERVER_MESSAGE"]) {
            DLog(@"%@", [listOfCommands objectAtIndex:1]);
        }
        else if ([command isEqualToString:@"WARNING"]) {
            if ([listOfCommands count] > 1)
                DLog(@"Server warning - %@", [listOfCommands objectAtIndex:1]);
            else
                DLog(@"Server warning - unknown");
        }
        else if ([command isEqualToString:@"ERROR"]) {
            DLog(@"Server error - %@", [listOfCommands objectAtIndex:1]);
        }
        else if ([command isEqualToString:@"BYE"]) {
            //TODO: handle "Reconnected too fast"
            DLog(@"Server disconnected, reason: %@", [listOfCommands objectAtIndex:1]);
            clientQuit = YES;
        }
        else {
            DLog(@"Unknown/Unsupported message received: %@", command);
        }
    }
    DLog(@"Server closed connection, ending thread");

    free(buffer);
    SDLNet_TCP_Close(self.ssd);
    SDLNet_Quit();

    }
}

@end
