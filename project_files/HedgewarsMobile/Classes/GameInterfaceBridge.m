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


#import "GameInterfaceBridge.h"
#import "PascalImports.h"
#import "EngineProtocolNetwork.h"
#import "OverlayViewController.h"
#import "StatsPageViewController.h"
#import "AudioManagerController.h"
#import "ObjcExports.h"

@implementation GameInterfaceBridge
@synthesize parentController, savePath, overlayController, engineProtocol, ipcPort, gameType;

-(id) initWithController:(id) viewController {
    if (self = [super init]) {
        self.ipcPort = randomPort();
        self.gameType = gtNone;
        self.savePath = nil;

        self.parentController = (UIViewController *)viewController;
        self.engineProtocol = [[EngineProtocolNetwork alloc] initOnPort:self.ipcPort];
        self.engineProtocol.delegate = self;

        self.overlayController = [[OverlayViewController alloc] initWithNibName:@"OverlayViewController" bundle:nil];
    }
    return self;
}

-(void) dealloc {
    releaseAndNil(engineProtocol);
    releaseAndNil(savePath);
    releaseAndNil(overlayController);
    [super dealloc];
}

#pragma mark -
// overlay with controls, become visible later, with a transparency effect since the sdlwindow is not yet created
-(void) displayOverlayLater:(id) object {
    // in order to get rotation events we have to insert the view inside the first view of the second window
    // when multihead we have to make sure that overlay is displayed in the touch-enabled window
    UIView *injected = (IS_DUALHEAD() ? self.parentController.view : UIVIEW_HW_SDLVIEW);
    [injected addSubview:self.overlayController.view];
}

// main routine for calling the actual game engine
-(void) startGameEngine {
    const char *gameArgs[11];
    NSInteger width, height;
    NSString *ipcString = [[NSString alloc] initWithFormat:@"%d", self.ipcPort];
    NSString *localeString = [[NSString alloc] initWithFormat:@"%@.txt", [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

    if (IS_DUALHEAD()) {
        CGRect screenBounds = [[[UIScreen screens] objectAtIndex:1] bounds];
        width = (int) screenBounds.size.width;
        height = (int) screenBounds.size.height;
    } else {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        width = (int) screenBounds.size.height;
        height = (int) screenBounds.size.width;
    }

    NSString *horizontalSize = [[NSString alloc] initWithFormat:@"%d", width * (int)getScreenScale()];
    NSString *verticalSize = [[NSString alloc] initWithFormat:@"%d", height * (int)getScreenScale()];
    NSString *rotation = [[NSString alloc] initWithString:@"0"];

    NSString *modelId = getModelType();
    NSInteger tmpQuality;
    if ([modelId hasPrefix:@"iPhone1"] || [modelId hasPrefix:@"iPod1,1"] || [modelId hasPrefix:@"iPod2,1"])     // = iPhone and iPhone 3G or iPod Touch or iPod Touch 2G
        tmpQuality = 0x00000001 | 0x00000002 | 0x00000008 | 0x00000040;                 // rqLowRes | rqBlurryLand | rqSimpleRope | rqKillFlakes
    else if ([modelId hasPrefix:@"iPhone2"] || [modelId hasPrefix:@"iPod3"])                                    // = iPhone 3GS or iPod Touch 3G
        tmpQuality = 0x00000002 | 0x00000040;                                           // rqBlurryLand | rqKillFlakes
    else if ([modelId hasPrefix:@"iPad1"] || [modelId hasPrefix:@"iPod4"])                                      // = iPad 1G or iPod Touch 4G
        tmpQuality = 0x00000002;                                                        // rqBlurryLand
    else                                                                                                        // = everything else
        tmpQuality = 0;                                                                 // full quality

    // disable tooltips on iPhone
    if (IS_IPAD() == NO)
        tmpQuality = tmpQuality | 0x00000400;

    // prevents using an empty nickname
    NSString *username = [settings objectForKey:@"username"];
    if ([username length] == 0)
        username = [NSString stringWithFormat:@"MobileUser-%@",ipcString];

    gameArgs[ 0] = [ipcString UTF8String];                                                      //ipcPort
    gameArgs[ 1] = [horizontalSize UTF8String];                                                 //cScreenWidth
    gameArgs[ 2] = [verticalSize UTF8String];                                                   //cScreenHeight
    gameArgs[ 3] = [[NSString stringWithFormat:@"%d",tmpQuality] UTF8String];                   //quality
    gameArgs[ 4] = "en.txt";//[localeString UTF8String];                                        //cLocaleFName
    gameArgs[ 5] = [username UTF8String];                                                       //UserNick
    gameArgs[ 6] = [[[settings objectForKey:@"sound"] stringValue] UTF8String];                 //isSoundEnabled
    gameArgs[ 7] = [[[settings objectForKey:@"music"] stringValue] UTF8String];                 //isMusicEnabled
    gameArgs[ 8] = [[[settings objectForKey:@"alternate"] stringValue] UTF8String];             //cAltDamage
    gameArgs[ 9] = [rotation UTF8String];                                                       //rotateQt
    gameArgs[10] = (self.gameType == gtSave) ? [self.savePath UTF8String] : NULL;               //recordFileName

    [verticalSize release];
    [horizontalSize release];
    [rotation release];
    [localeString release];
    [ipcString release];

    objcExportsInit();

    // this is the pascal fuction that starts the game, wrapped around isInGame
    [HedgewarsAppDelegate sharedAppDelegate].isInGame = YES;
    Game(gameArgs);
    [HedgewarsAppDelegate sharedAppDelegate].isInGame = NO;
}

// prepares the controllers for hosting a game
-(void) prepareEngineLaunch {
    // we add a black view hiding the background
    CGRect theFrame = CGRectMake(0, 0, self.parentController.view.frame.size.height, self.parentController.view.frame.size.width);
    UIView *blackView = [[UIView alloc] initWithFrame:theFrame];
    [self.parentController.view addSubview:blackView];
    blackView.opaque = YES;
    blackView.backgroundColor = [UIColor blackColor];
    blackView.alpha = 0;
    // when dual screen we apply a little transition
    if (IS_DUALHEAD()) {
        [UIView beginAnimations:@"fade out" context:NULL];
        [UIView setAnimationDuration:1];
        blackView.alpha = 1;
        [UIView commitAnimations];
    } else
        blackView.alpha = 1;

    // prepare options for overlay and add it to the future sdl uiwindow
    [self performSelector:@selector(displayOverlayLater:) withObject:nil afterDelay:3];

    // keep track of uncompleted games
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.savePath forKey:@"savedGamePath"];
    [userDefaults synchronize];

    [AudioManagerController pauseBackgroundMusic];

    // SYSTEMS ARE GO!!
    [self startGameEngine];
    
    // remove completed games notification
    [userDefaults setObject:@"" forKey:@"savedGamePath"];
    [userDefaults synchronize];

    // now we can remove the cover with a transition
    blackView.frame = theFrame;
    blackView.alpha = 1;
    [UIView beginAnimations:@"fade in" context:NULL];
    [UIView setAnimationDuration:1];
    blackView.alpha = 0;
    [UIView commitAnimations];
    [blackView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
    [blackView release];

    // the overlay is not needed any more and can be removed
    [self.overlayController removeOverlay];

    // warn our host that it's going to be visible again
    [self.parentController viewWillAppear:YES];

    [AudioManagerController playBackgroundMusic];
}

// set up variables for a local game
-(void) startLocalGame:(NSDictionary *)withDictionary {
    self.gameType = gtLocal;

    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"yyyy-MM-dd '@' HH.mm"];
    NSString *path = [[NSString alloc] initWithFormat:@"%@%@.hws",SAVES_DIRECTORY(),[outputFormatter stringFromDate:[NSDate date]]];
    [outputFormatter release];
    self.savePath = path;
    [path release];

    // in the rare case in which a savefile with the same name exists the older one must be removed (or it gets corrupted)
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.savePath])
        [[NSFileManager defaultManager] removeItemAtPath:self.savePath error:nil];

    [self.engineProtocol spawnThread:self.savePath withOptions:withDictionary];
    [self prepareEngineLaunch];
}

// set up variables for a save game
-(void) startSaveGame:(NSString *)atPath {
    self.gameType = gtSave;
    self.savePath = atPath;

    [self.engineProtocol spawnThread:self.savePath];
    [self prepareEngineLaunch];
}

-(void) gameHasEndedWithStats:(NSArray *)stats {
    // wrap this around a retain/realse to prevent being deallocated too soon
    [self retain];
    // display stats page if there is something to display
    if (stats != nil) {
        StatsPageViewController *statsPage = [[StatsPageViewController alloc] initWithStyle:UITableViewStyleGrouped];
        statsPage.statsArray = stats;
        statsPage.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        if ([statsPage respondsToSelector:@selector(setModalPresentationStyle:)])
            statsPage.modalPresentationStyle = UIModalPresentationPageSheet;

        [self.parentController presentModalViewController:statsPage animated:YES];
        [statsPage release];
    }

    // can remove the savefile if the replay has ended
    if (self.gameType == gtSave)
        [[NSFileManager defaultManager] removeItemAtPath:self.savePath error:nil];
    [self release];
}

@end
