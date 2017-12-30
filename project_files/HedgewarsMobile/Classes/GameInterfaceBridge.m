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


#import "GameInterfaceBridge.h"
#import "EngineProtocolNetwork.h"
#import "StatsPageViewController.h"


static UIViewController *callingController;

@implementation GameInterfaceBridge
@synthesize blackView, savePath, port;

#pragma mark -
#pragma mark Instance methods for engine interaction
// prepares the controllers for hosting a game
- (void)earlyEngineLaunch:(NSDictionary *)optionsOrNil {
    [[AudioManagerController mainManager] fadeOutBackgroundMusic];

    EngineProtocolNetwork *engineProtocol = [[EngineProtocolNetwork alloc] init];
    self.port = engineProtocol.enginePort;
    engineProtocol.delegate = self;
    [engineProtocol spawnThread:self.savePath withOptions:optionsOrNil];

    // add a black view hiding the background
    UIWindow *thisWindow = [[HedgewarsAppDelegate sharedAppDelegate] uiwindow];
    self.blackView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.blackView.opaque = YES;
    self.blackView.backgroundColor = [UIColor blackColor];
    self.blackView.alpha = 0;
    self.blackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [UIView beginAnimations:@"fade out" context:NULL];
    [UIView setAnimationDuration:1];
    self.blackView.alpha = 1;
    [UIView commitAnimations];
    [thisWindow addSubview:self.blackView];

    // keep the point of return for games that completed loading
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.savePath forKey:@"savedGamePath"];
    [userDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"saveIsValid"];
    [userDefaults synchronize];

    // let's launch the engine using this -perfomSelector so that the runloop can deal with queued messages first
    [self performSelector:@selector(engineLaunch) withObject:nil afterDelay:0.1f];
}

// cleans up everything
- (void)lateEngineLaunch {
    // notify views below that they are getting the spotlight again
    [[[HedgewarsAppDelegate sharedAppDelegate] uiwindow] makeKeyAndVisible];
    [callingController viewWillAppear:YES];

    // remove completed games notification
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"" forKey:@"savedGamePath"];
    [userDefaults synchronize];

    // remove the cover view with a transition
    self.blackView.alpha = 1;
    [UIView beginAnimations:@"fade in" context:NULL];
    [UIView setAnimationDuration:1];
    self.blackView.alpha = 0;
    [UIView commitAnimations];
    [self.blackView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];

    // can remove the savefile if the replay has ended
    if ([HWUtils gameType] == gtSave)
        [[NSFileManager defaultManager] removeItemAtPath:self.savePath error:nil];

    // restart music and we're done
    [[AudioManagerController mainManager] fadeInBackgroundMusic];
    [HWUtils setGameStatus:gsNone];
    [HWUtils setGameType:gtNone];
}

// main routine for calling the actual game engine
- (void)engineLaunch {
    CGFloat width, height;
    CGFloat screenScale = [[UIScreen mainScreen] safeScale];
    NSString *ipcString = [[NSString alloc] initWithFormat:@"%d",self.port];
    
    NSString *localeString = [[NSString alloc] initWithFormat:@"%@.txt", [HWUtils languageID]];
    
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

    CGRect screenBounds = [[UIScreen mainScreen] safeBounds];
    width = screenBounds.size.width;
    height = screenBounds.size.height;

    NSString *horizontalSize = [[NSString alloc] initWithFormat:@"%d", (int)(width * screenScale)];
    NSString *verticalSize = [[NSString alloc] initWithFormat:@"%d", (int)(height * screenScale)];
    NSString *resourcePath = [[NSString alloc] initWithFormat:@"%@/Data", [[NSBundle mainBundle] resourcePath]];

    NSString *modelId = [HWUtils modelType];
    NSInteger tmpQuality;
    if ([modelId hasPrefix:@"iPhone1"] || [modelId hasPrefix:@"iPod1,1"] || [modelId hasPrefix:@"iPod2,1"])     // = iPhone and iPhone 3G or iPod Touch or iPod Touch 2G
        tmpQuality = 0x00000001 | 0x00000002 | 0x00000008 | 0x00000040;                 // rqLowRes | rqBlurryLand | rqSimpleRope | rqKillFlakes
    else if ([modelId hasPrefix:@"iPhone2"] || [modelId hasPrefix:@"iPod3"])                                    // = iPhone 3GS or iPod Touch 3G
        tmpQuality = 0x00000002 | 0x00000040;                                           // rqBlurryLand | rqKillFlakes
    else if ([modelId hasPrefix:@"iPad1"] || [modelId hasPrefix:@"iPod4"])                                      // = iPad 1G or iPod Touch 4G
        tmpQuality = 0x00000002;                                                        // rqBlurryLand
    else                                                                                                        // = everything else
        tmpQuality = 0;                                                                 // full quality

    // disable ammomenu animation
    tmpQuality = tmpQuality | 0x00000080;
    // disable tooltips on iPhone
    if (IS_IPAD() == NO)
        tmpQuality = tmpQuality | 0x00000400;
    NSString *rawQuality = [NSString stringWithFormat:@"%d",tmpQuality];
    NSString *documentsDirectory = DOCUMENTS_FOLDER();

    NSMutableArray *gameParameters = [[NSMutableArray alloc] initWithObjects:
                                      @"--internal",
                                      @"--port", ipcString,
                                      @"--width", horizontalSize,
                                      @"--height", verticalSize,
                                      @"--raw-quality", rawQuality,
                                      @"--locale", localeString,
                                      @"--prefix", resourcePath,
                                      @"--user-prefix", documentsDirectory,
                                      nil];

    NSString *username = [settings objectForKey:@"username"];
    if ([username length] > 0) {
        [gameParameters addObject:@"--nick"];
        [gameParameters addObject: username];
    }

    if ([[settings objectForKey:@"sound"] boolValue] == NO)
        [gameParameters addObject:@"--nosound"];

    if ([[settings objectForKey:@"music"] boolValue] == NO)
        [gameParameters addObject:@"--nomusic"];

    if([[settings objectForKey:@"alternate"] boolValue] == YES)
        [gameParameters addObject:@"--altdmg"];

#ifdef DEBUG
    [gameParameters addObject:@"--showfps"];
#endif

    if ([HWUtils gameType] == gtSave)
        [gameParameters addObject:self.savePath];

    [HWUtils setGameStatus:gsLoading];

    int argc = [gameParameters count];
    const char **argv = (const char **)malloc(sizeof(const char*)*argc);
    for (int i = 0; i < argc; i++)
        argv[i] = strdup([[gameParameters objectAtIndex:i] UTF8String]);

    // this is the pascal function that starts the game
    RunEngine(argc, argv);

    // cleanup
    for (int i = 0; i < argc; i++)
        free((void *)argv[i]);
    free(argv);

    // moar cleanup
    [self lateEngineLaunch];
}


#pragma mark -
#pragma mark EngineProtocolDelegate methods
- (void)gameEndedWithStatistics:(NSArray *)stats {
    if (stats != nil) {
        StatsPageViewController *statsPage = [[StatsPageViewController alloc] init];
        statsPage.statsArray = stats;
        statsPage.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [callingController presentViewController:statsPage animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Class methods for setting up the engine from outsite
+ (void)registerCallingController:(UIViewController *)controller {
    callingController = controller;
}

+ (void)startGame:(TGameType)type atPath:(NSString *)path withOptions:(NSDictionary *)config {
    [HWUtils setGameType:type];
    id bridge = [[self alloc] init];
    [bridge setSavePath:path];
    [bridge earlyEngineLaunch:config];
}

+ (void)startLocalGame:(NSDictionary *)withOptions {
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"yyyy-MM-dd '@' HH.mm"];
    NSString *savePath = [[NSString alloc] initWithFormat:@"%@%@.hws",SAVES_DIRECTORY(),[outputFormatter stringFromDate:[NSDate date]]];

    // in the rare case in which a savefile with the same name exists the older one must be removed (otherwise it gets corrupted)
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath])
        [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];

    [self startGame:gtLocal atPath:savePath withOptions:withOptions];
}

+ (void)startSaveGame:(NSString *)atPath {
    [self startGame:gtSave atPath:atPath withOptions:nil];
}

+ (void)startMissionGame:(NSString *)withScript {
    NSString *seedCmd = [self seedCommand];
    NSString *missionPath = [[NSString alloc] initWithFormat:@"escript Missions/Training/%@.lua",withScript];
    NSDictionary *missionDict = [[NSDictionary alloc] initWithObjectsAndKeys:missionPath, @"mission_command", seedCmd, @"seed_command", nil];

    [self startGame:gtMission atPath:nil withOptions:missionDict];
}

+ (NSString *)seedCommand {
    // generate a seed
    NSString *seed = [HWUtils seed];
    NSString *seedCmd = [[NSString alloc] initWithFormat:@"eseed {%@}", seed];
    return seedCmd;
}

+ (void)startCampaignMissionGameWithScript:(NSString *)missionScriptName forCampaign:(NSString *)campaignName {
    NSString *seedCmd = [self seedCommand];
    NSString *campaignMissionPath = [[NSString alloc] initWithFormat:@"escript Missions/Campaign/%@/%@", campaignName, missionScriptName];
    NSDictionary *campaignMissionDict = [[NSDictionary alloc] initWithObjectsAndKeys:campaignMissionPath, @"mission_command", seedCmd, @"seed_command", nil];
    
    [self startGame:gtCampaign atPath:nil withOptions:campaignMissionDict];
}

+ (void)startSimpleGame {
    NSString *seedCmd = [self seedCommand];

    // pick a random static map
    NSArray *listOfMaps = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:MAPS_DIRECTORY() error:NULL];
    NSString *mapName = [listOfMaps objectAtIndex:arc4random_uniform((int)[listOfMaps count])];
    NSString *fileCfg = [[NSString alloc] initWithFormat:@"%@/%@/map.cfg",MAPS_DIRECTORY(),mapName];
    NSString *contents = [[NSString alloc] initWithContentsOfFile:fileCfg encoding:NSUTF8StringEncoding error:NULL];
    NSArray *split = [contents componentsSeparatedByString:@"\n"];
    NSString *themeCommand = [[NSString alloc] initWithFormat:@"etheme %@", [split objectAtIndex:0]];
    NSString *staticMapCommand = [[NSString alloc] initWithFormat:@"emap %@", mapName];

    // select teams with two different colors
    NSArray *colorArray = [HWUtils teamColors];
    NSInteger firstColorIndex, secondColorIndex;
    do {
        firstColorIndex = arc4random_uniform((int)[colorArray count]);
        secondColorIndex = arc4random_uniform((int)[colorArray count]);
    } while (firstColorIndex == secondColorIndex);
    unsigned int firstColor = [[colorArray objectAtIndex:firstColorIndex] intValue];
    unsigned int secondColor = [[colorArray objectAtIndex:secondColorIndex] intValue];

    NSDictionary *firstTeam = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:4],@"number",
                                                                           [NSNumber numberWithUnsignedInt:firstColor],@"color",
                                                                           @"Ninjas.plist",@"team",nil];
    NSDictionary *secondTeam = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:4],@"number",
                                                                            [NSNumber numberWithUnsignedInt:secondColor],@"color",
                                                                            @"Robots.plist",@"team",nil];
    NSArray *listOfTeams = [[NSArray alloc] initWithObjects:firstTeam,secondTeam,nil];

    // create the configuration
    NSDictionary *gameDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    seedCmd,@"seed_command",
                                    @"e$template_filter 0",@"templatefilter_command",
                                    @"e$mapgen 0",@"mapgen_command",
                                    @"e$maze_size 0",@"mazesize_command",
                                    themeCommand,@"theme_command",
                                    staticMapCommand,@"staticmap_command",
                                    listOfTeams,@"teams_list",
                                    @"Default.plist",@"scheme",
                                    @"Default.plist",@"weapon",
                                    @"",@"mission_command",
                                    nil];

    // launch game
    [GameInterfaceBridge startLocalGame:gameDictionary];
}

@end
