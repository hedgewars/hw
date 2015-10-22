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


#import "EngineProtocolNetwork.h"


#define BUFFER_SIZE 255     // like in original frontend

@implementation EngineProtocolNetwork
@synthesize delegate, stream, csd, enginePort;

-(id) initWithPort:(NSInteger) port {
    if ((self = [super init])) {
        self.delegate = nil;
        self.csd = NULL;
        self.stream = nil;
        self.enginePort = port;
    }
    return self;
}

-(id) init {
    return [self initWithPort:[HWUtils randomPort]];
}

-(void) dealloc {
    self.delegate = nil;
    releaseAndNil(stream);
    [super dealloc];
}

#pragma mark -
#pragma mark Spawner functions
-(void) spawnThread:(NSString *)onSaveFile withOptions:(NSDictionary *)dictionary {
    self.stream = (onSaveFile) ? [[NSOutputStream alloc] initToFileAtPath:onSaveFile append:YES] : nil;
    [self.stream open];

    // +detachNewThreadSelector retain/release self automatically
    [NSThread detachNewThreadSelector:@selector(engineProtocol:)
                             toTarget:self
                           withObject:dictionary];
}

#pragma mark -
#pragma mark Provider functions
// unpacks team data from the selected team.plist to a sequence of engine commands
-(void) provideTeamData:(NSString *)teamName forHogs:(NSInteger) numberOfPlayingHogs withHealth:(NSInteger) initialHealth ofColor:(NSNumber *)teamColor {
    /*
     addteam <32charsMD5hash> <color> <team name>
     addhh <level> <health> <hedgehog name>
     <level> is 0 for human, 1-5 for bots (5 is the most stupid)
    */

    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@", TEAMS_DIRECTORY(), teamName];
    NSDictionary *teamData = [[NSDictionary alloc] initWithContentsOfFile:teamFile];
    [teamFile release];

    NSString *teamHashColorAndName = [[NSString alloc] initWithFormat:@"eaddteam %@ %@ %@",
                                      [teamData objectForKey:@"hash"], [teamColor stringValue], [teamName stringByDeletingPathExtension]];
    [self sendToEngine: teamHashColorAndName];
    [teamHashColorAndName release];

    NSString *grave = [[NSString alloc] initWithFormat:@"egrave %@", [teamData objectForKey:@"grave"]];
    [self sendToEngine: grave];
    [grave release];

    NSString *fort = [[NSString alloc] initWithFormat:@"efort %@", [teamData objectForKey:@"fort"]];
    [self sendToEngine: fort];
    [fort release];

    NSString *voicepack = [[NSString alloc] initWithFormat:@"evoicepack %@", [teamData objectForKey:@"voicepack"]];
    [self sendToEngine: voicepack];
    [voicepack release];

    NSString *flag = [[NSString alloc] initWithFormat:@"eflag %@", [teamData objectForKey:@"flag"]];
    [self sendToEngine: flag];
    [flag release];

    NSArray *hogs = [teamData objectForKey:@"hedgehogs"];
    for (int i = 0; i < numberOfPlayingHogs; i++) {
        NSDictionary *hog = [hogs objectAtIndex:i];

        NSString *hogLevelHealthAndName = [[NSString alloc] initWithFormat:@"eaddhh %@ %ld %@",
                                           [hog objectForKey:@"level"], (long)initialHealth, [hog objectForKey:@"hogname"]];
        [self sendToEngine: hogLevelHealthAndName];
        [hogLevelHealthAndName release];

        NSString *hogHat = [[NSString alloc] initWithFormat:@"ehat %@", [hog objectForKey:@"hat"]];
        [self sendToEngine: hogHat];
        [hogHat release];
    }

    [teamData release];
}

// unpacks ammostore data from the selected ammo.plist to a sequence of engine commands
-(void) provideAmmoData:(NSString *)ammostoreName forPlayingTeams:(NSInteger) numberOfTeams {
    NSString *weaponPath = [[NSString alloc] initWithFormat:@"%@/%@",WEAPONS_DIRECTORY(),ammostoreName];
    NSDictionary *ammoData = [[NSDictionary alloc] initWithContentsOfFile:weaponPath];
    [weaponPath release];

    // if we're loading an older version of ammos fill the engine message with 0s
    int diff = HW_getNumberOfWeapons() - [[ammoData objectForKey:@"ammostore_initialqt"] length];
    NSString *update = @"";
    while ((int)[update length] < diff)
        update = [update stringByAppendingString:@"0"];

    NSString *ammloadt = [[NSString alloc] initWithFormat:@"eammloadt %@%@", [ammoData objectForKey:@"ammostore_initialqt"], update];
    [self sendToEngine: ammloadt];
    [ammloadt release];

    NSString *ammprob = [[NSString alloc] initWithFormat:@"eammprob %@%@", [ammoData objectForKey:@"ammostore_probability"], update];
    [self sendToEngine: ammprob];
    [ammprob release];

    NSString *ammdelay = [[NSString alloc] initWithFormat:@"eammdelay %@%@", [ammoData objectForKey:@"ammostore_delay"], update];
    [self sendToEngine: ammdelay];
    [ammdelay release];

    NSString *ammreinf = [[NSString alloc] initWithFormat:@"eammreinf %@%@", [ammoData objectForKey:@"ammostore_crate"], update];
    [self sendToEngine: ammreinf];
    [ammreinf release];

    // send this for each team so it applies the same ammostore to all teams
    NSString *ammstore = [[NSString alloc] initWithString:@"eammstore"];
    for (int i = 0; i < numberOfTeams; i++)
        [self sendToEngine: ammstore];
    [ammstore release];

    [ammoData release];
}

// unpacks scheme data from the selected scheme.plist to a sequence of engine commands
-(NSInteger) provideScheme:(NSString *)schemeName {
    NSString *schemePath = [[NSString alloc] initWithFormat:@"%@/%@",SCHEMES_DIRECTORY(),schemeName];
    NSDictionary *schemeDictionary = [[NSDictionary alloc] initWithContentsOfFile:schemePath];
    [schemePath release];
    NSArray *basicArray = [schemeDictionary objectForKey:@"basic"];
    NSArray *gamemodArray = [schemeDictionary objectForKey:@"gamemod"];
    int result = 0;
    int mask = 0x00000004;

    // pack the game modifiers in a single var and send it
    for (NSNumber *value in gamemodArray) {
        if ([value boolValue] == YES)
            result |= mask;
        mask <<= 1;
    }
    NSString *flags = [[NSString alloc] initWithFormat:@"e$gmflags %d",result];
    [self sendToEngine:flags];
    [flags release];

    // basic game flags
    result = [[basicArray objectAtIndex:0] intValue];
    NSArray *basic = [[NSArray alloc] initWithContentsOfFile:BASICFLAGS_FILE()];

    for (NSUInteger i = 1; i < [basicArray count]; i++) {
        NSDictionary *dict = [basic objectAtIndex:i];
        NSString *command = [dict objectForKey:@"command"];
        NSInteger value = [[basicArray objectAtIndex:i] intValue];
        if ([[dict objectForKey:@"checkOverMax"] boolValue] && value >= [[dict objectForKey:@"max"] intValue])
            value = 9999;
        if ([[dict objectForKey:@"times1000"] boolValue])
            value = value * 1000;
        NSString *strToSend = [[NSString alloc] initWithFormat:@"%@ %d",command,value];
        [self sendToEngine:strToSend];
        [strToSend release];
    }
    [basic release];

    [schemeDictionary release];
    return result;
}

#pragma mark -
#pragma mark Network relevant code
-(void) dumpRawData:(const char *)buffer ofSize:(uint8_t) length {
    [self.stream write:&length maxLength:1];
    [self.stream write:(const uint8_t *)buffer maxLength:length];
}

// wrapper that computes the length of the message and then sends the command string, saving the command on a file
-(int) sendToEngine:(NSString *)string {
    uint8_t length = [string length];

    [self dumpRawData:[string UTF8String] ofSize:length];
    SDLNet_TCP_Send(csd, &length, 1);
    return SDLNet_TCP_Send(csd, [string UTF8String], length);
}

// wrapper that computes the length of the message and then sends the command string, skipping file writing
-(int) sendToEngineNoSave:(NSString *)string {
    uint8_t length = [string length];

    SDLNet_TCP_Send(csd, &length, 1);
    return SDLNet_TCP_Send(csd, [string UTF8String], length);
}

// this is launched as thread and handles all IPC with engine
-(void) engineProtocol:(id) object {
    @autoreleasepool {
    
    NSDictionary *gameConfig = (NSDictionary *)object;
    NSMutableArray *statsArray = nil;
    TCPsocket sd;
    IPaddress ip;
    int eProto;
    BOOL clientQuit;
    char const buffer[BUFFER_SIZE];
    uint8_t msgSize;

    clientQuit = NO;
    csd = NULL;

    if (SDLNet_Init() < 0) {
        DLog(@"SDLNet_Init: %s", SDLNet_GetError());
        clientQuit = YES;
    }

    // Resolving the host using NULL make network interface to listen
    if (SDLNet_ResolveHost(&ip, NULL, self.enginePort) < 0 && !clientQuit) {
        DLog(@"SDLNet_ResolveHost: %s\n", SDLNet_GetError());
        clientQuit = YES;
    }

    // Open a connection with the IP provided (listen on the host's port)
    if (!(sd = SDLNet_TCP_Open(&ip)) && !clientQuit) {
        DLog(@"SDLNet_TCP_Open: %s %d\n", SDLNet_GetError(), self.enginePort);
        clientQuit = YES;
    }

    DLog(@"Waiting for a client on port %d", self.enginePort);
    while (csd == NULL)
        csd = SDLNet_TCP_Accept(sd);
    SDLNet_TCP_Close(sd);

    while (!clientQuit) {
        msgSize = 0;
        memset((void *)buffer, '\0', BUFFER_SIZE);
        if (SDLNet_TCP_Recv(csd, &msgSize, sizeof(uint8_t)) <= 0)
            break;
        if (SDLNet_TCP_Recv(csd, (void *)buffer, msgSize) <= 0)
            break;

        switch (buffer[0]) {
            case 'C':
                DLog(@"Sending game config...\n%@", gameConfig);

                /*if (isNetGame == YES)
                    [self sendToEngineNoSave:@"TN"];
                else*/
                    [self sendToEngineNoSave:@"TL"];
                NSString *saveHeader = @"TS";
                [self dumpRawData:[saveHeader UTF8String] ofSize:[saveHeader length]];

                // lua script (if set)
                NSString *script = [gameConfig objectForKey:@"mission_command"];
                if ([script length] != 0)
                    [self sendToEngine:script];
                // missions/tranings only need the script configuration set
                if ([gameConfig count] == 1)
                    break;

                // seed info
                [self sendToEngine:[gameConfig objectForKey:@"seed_command"]];

                // dimension of the map
                [self sendToEngine:[gameConfig objectForKey:@"templatefilter_command"]];
                [self sendToEngine:[gameConfig objectForKey:@"mapgen_command"]];
                [self sendToEngine:[gameConfig objectForKey:@"mazesize_command"]];

                // static land (if set)
                NSString *staticMap = [gameConfig objectForKey:@"staticmap_command"];
                if ([staticMap length] != 0)
                    [self sendToEngine:staticMap];

                // theme info
                [self sendToEngine:[gameConfig objectForKey:@"theme_command"]];

                // scheme (returns initial health)
                NSInteger health = [self provideScheme:[gameConfig objectForKey:@"scheme"]];

                // send an ammostore for each team
                NSArray *teamsConfig = [gameConfig objectForKey:@"teams_list"];
                [self provideAmmoData:[gameConfig objectForKey:@"weapon"] forPlayingTeams:[teamsConfig count]];

                // finally add hogs
                for (NSDictionary *teamData in teamsConfig) {
                    [self provideTeamData:[teamData objectForKey:@"team"]
                                  forHogs:[[teamData objectForKey:@"number"] intValue]
                               withHealth:health
                                  ofColor:[teamData objectForKey:@"color"]];
                }
                break;
            case '?':
                DLog(@"Ping? Pong!");
                [self sendToEngine:@"!"];
                break;
            case 'E':
                DLog(@"ERROR - last console line: [%s]", &buffer[1]);
                clientQuit = YES;
                break;
            case 'e':
                [self dumpRawData:buffer ofSize:msgSize];

                sscanf((char *)buffer, "%*s %d", &eProto);
                int netProto;
                char *versionStr;

                HW_versionInfo(&netProto, &versionStr);
                if (netProto == eProto) {
                    DLog(@"Setting protocol version %d (%s)", eProto, versionStr);
                } else {
                    DLog(@"ERROR - wrong protocol number: %d (expecting %d)", netProto, eProto);
                    clientQuit = YES;
                }
                break;
            case 'i':
                if (statsArray == nil) {
                    statsArray = [[NSMutableArray alloc] initWithCapacity:10 - 2];
                    NSMutableArray *ranking = [[NSMutableArray alloc] initWithCapacity:4];
                    [statsArray insertObject:ranking atIndex:0];
                    [ranking release];
                }
                NSString *tempStr = [NSString stringWithUTF8String:&buffer[2]];
                NSArray *info = [tempStr componentsSeparatedByString:@" "];
                NSString *arg = [info objectAtIndex:0];
                int index = [arg length] + 3;
                switch (buffer[1]) {
                    case 'r':           // winning team
                        [statsArray insertObject:[NSString stringWithUTF8String:&buffer[2]] atIndex:1];
                        break;
                    case 'D':           // best shot
                        [statsArray addObject:[NSString stringWithFormat:NSLocalizedString(@"The best shot award won by %s (with %@ points)", nil), &buffer[index], arg]];
                        break;
                    case 'k':           // best hedgehog
                        [statsArray addObject:[NSString stringWithFormat:NSLocalizedString(@"The best killer is %s with %@ kill(s) in a turn", nil), &buffer[index], arg]];
                        break;
                    case 'K':           // number of hogs killed
                        [statsArray addObject:[NSString stringWithFormat:NSLocalizedString(@"%@ hedgehog(s) were killed during this round", nil), arg]];
                        break;
                    case 'H':           // team health/graph
                        break;
                    case 'T':           // local team stats
                        // still WIP in statsPage.cpp
                        break;
                    case 'P':           // teams ranking
                        [[statsArray objectAtIndex:0] addObject:tempStr];
                        break;
                    case 's':           // self damage
                        [statsArray addObject:[NSString stringWithFormat:NSLocalizedString(@"%s thought it's good to shoot his own hedgehogs with %@ points", nil), &buffer[index], arg]];
                        break;
                    case 'S':           // friendly fire
                        [statsArray addObject:[NSString stringWithFormat:NSLocalizedString(@"%s killed %@ of his own hedgehogs", nil), &buffer[index], arg]];
                        break;
                    case 'B':           // turn skipped
                        [statsArray addObject:[NSString stringWithFormat:NSLocalizedString(@"%s was scared and skipped turn %@ times", nil), &buffer[index], arg]];
                        break;
                    default:
                        DLog(@"Unhandled stat message, see statsPage.cpp");
                        break;
                }
                break;
            case 'q':
                // game ended and match finished, statsArray is full of delicious statistics
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(gameEndedWithStatistics:)])
                    [self.delegate gameEndedWithStatistics:statsArray];
                [statsArray release];
                [HWUtils setGameStatus:gsEnded];
                // closing connection here would trigger a "IPC connection lost" error, so we have to wait until recv fails
                break;
            case 'Q':
                // game exited but not completed, skip this message in the savefile
                [HWUtils setGameStatus:gsInterrupted];
                // same here, don't set clientQuit to YES
                break;
            default:
                [self dumpRawData:buffer ofSize:msgSize];
                break;
        }
    }
    DLog(@"Engine exited, ending thread");

    [self.stream close];
    [self.stream release];

    // Close the client socket
    [HWUtils freePort:self.enginePort];
    SDLNet_TCP_Close(csd);
    SDLNet_Quit();
    
    }

    // Invoking this method should be avoided as it does not give your thread a chance
    // to clean up any resources it allocated during its execution.
    //[NSThread exit];
}

@end
