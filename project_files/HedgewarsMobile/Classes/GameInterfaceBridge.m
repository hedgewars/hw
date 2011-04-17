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

#define BUFFER_SIZE 255     // like in original frontend

@implementation GameInterfaceBridge
@synthesize parentController, systemSettings, savePath, overlayController, ipcPort, gameType, engineProtocol;

-(id) initWithController:(id) viewController {
    if (self = [super init]) {
        self.parentController = (UIViewController *)viewController;
        self.engineProtocol = [[EngineProtocolNetwork alloc] init];
;
        self.savePath = nil;

        self.systemSettings = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_FILE()];
        self.overlayController = [[OverlayViewController alloc] initWithNibName:@"OverlayViewController" bundle:nil];
        self.ipcPort = randomPort();

        self.gameType = gtNone;
    }
    return self;
}

-(void) dealloc {
    releaseAndNil(parentController);
    releaseAndNil(engineProtocol);
    releaseAndNil(systemSettings);
    releaseAndNil(savePath);
    releaseAndNil(overlayController);
    [super dealloc];
}

#pragma mark -
// overlay with controls, become visible later, with a transparency effect since the sdlwindow is not yet created
-(void) displayOverlayLater:(id) object {
    NSDictionary *dict = (NSDictionary *)object;

    [self.overlayController setUseClassicMenu:[[dict objectForKey:@"menu"] boolValue]];
    [self.overlayController setInitialOrientation:[[dict objectForKey:@"orientation"] intValue]];

    UIWindow *gameWindow = (IS_DUALHEAD() ? [HedgewarsAppDelegate sharedAppDelegate].uiwindow : [[UIApplication sharedApplication] keyWindow]);
    [gameWindow addSubview:self.overlayController.view];
}

// main routine for calling the actual game engine
-(void) startGameEngine {
    self.parentController.view.opaque = YES;
    self.parentController.view.backgroundColor = [UIColor blackColor];
    self.parentController.view.alpha = 0;

    [UIView beginAnimations:@"fade out to black" context:NULL];
    [UIView setAnimationDuration:1];
    self.parentController.view.alpha = 1;
    [UIView commitAnimations];

    self.engineProtocol.savePath = self.savePath;
    [self.engineProtocol spawnThreadOnPort:self.ipcPort];

    NSDictionary *overlayOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithInt:self.parentController.interfaceOrientation],@"orientation",
                                    [self.systemSettings objectForKey:@"menu"],@"menu",
                                    nil];
    [self performSelector:@selector(displayOverlayLater:) withObject:overlayOptions afterDelay:1];
    [overlayOptions release];

    // this is the pascal fuction that starts the game, wrapped around isInGame
    [HedgewarsAppDelegate sharedAppDelegate].isInGame = YES;
    Game([self gatherGameSettings]);
    [HedgewarsAppDelegate sharedAppDelegate].isInGame = NO;

    [UIView beginAnimations:@"fade in" context:NULL];
    [UIView setAnimationDuration:1];
    self.parentController.view.alpha = 0;
    [UIView commitAnimations];
}

-(void) startLocalGame:(NSDictionary *)withDictionary {
    self.gameType = gtLocal;
    [self.engineProtocol setGameConfig:withDictionary];
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"yyyy-MM-dd '@' HH.mm"];
    NSString *newDateString = [outputFormatter stringFromDate:[NSDate date]];
    self.savePath = [SAVES_DIRECTORY() stringByAppendingFormat:@"%@.hws", newDateString];
    [outputFormatter release];
    
    [self startGameEngine];
}

-(void) startSaveGame:(NSString *)atPath {
    self.gameType = gtSave;
    self.savePath = atPath;
    [self.engineProtocol setGameConfig:nil];

    [self startGameEngine];
}

#pragma mark -
-(const char **)gatherGameSettings {
    const char *gameArgs[10];
    NSInteger width, height, orientation;
    NSString *ipcString = [[NSString alloc] initWithFormat:@"%d", self.ipcPort];
    NSString *localeString = [[NSString alloc] initWithFormat:@"%@.txt", [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];

    if (IS_DUALHEAD()) {
        CGRect screenBounds = [[[UIScreen screens] objectAtIndex:1] bounds];
        width = (int) screenBounds.size.width;
        height = (int) screenBounds.size.height;
        orientation = 0;
    } else {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        width = (int) screenBounds.size.height;
        height = (int) screenBounds.size.width;
        orientation = (self.parentController.interfaceOrientation == UIDeviceOrientationLandscapeLeft) ? -90 : 90;
    }

    NSString *horizontalSize = [[NSString alloc] initWithFormat:@"%d", width];
    NSString *verticalSize = [[NSString alloc] initWithFormat:@"%d", height];
    NSString *rotation = [[NSString alloc] initWithFormat:@"%d", orientation];
    BOOL enhanced = [[self.systemSettings objectForKey:@"enhanced"] boolValue];

    NSString *modelId = modelType();
    NSInteger tmpQuality;
    if ([modelId hasPrefix:@"iPhone1"] || [modelId hasPrefix:@"iPod1,1"] || [modelId hasPrefix:@"iPod2,1"])     // = iPhone and iPhone 3G or iPod Touch or iPod Touch 2G
        tmpQuality = 0x00000001 | 0x00000002 | 0x00000008 | 0x00000040;                 // rqLowRes | rqBlurryLand | rqSimpleRope | rqKillFlakes
    else if ([modelId hasPrefix:@"iPhone2"] || [modelId hasPrefix:@"iPod3"])                                    // = iPhone 3GS or iPod Touch 3G
        tmpQuality = 0x00000002 | 0x00000040;                                           // rqBlurryLand | rqKillFlakes
    else if ([modelId hasPrefix:@"iPad1"] || [modelId hasPrefix:@"iPod4"] || enhanced == NO)                    // = iPad 1G or iPod Touch 4G or not enhanced mode
        tmpQuality = 0x00000002;                                                        // rqBlurryLand
    else                                                                                                        // = everything else
        tmpQuality = 0;                                                                 // full quality

    // disable tooltips on iPhone
    if (IS_IPAD() == NO)
        tmpQuality = tmpQuality | 0x00000400;

    // prevents using an empty nickname
    NSString *username = [self.systemSettings objectForKey:@"username"];
    if ([username length] == 0)
        username = [NSString stringWithFormat:@"MobileUser-%@",ipcString];

    gameArgs[ 0] = [ipcString UTF8String];                                                      //ipcPort
    gameArgs[ 1] = [horizontalSize UTF8String];                                                 //cScreenWidth
    gameArgs[ 2] = [verticalSize UTF8String];                                                   //cScreenHeight
    gameArgs[ 3] = [[NSString stringWithFormat:@"%d",tmpQuality] UTF8String];                   //quality
    gameArgs[ 4] = "en.txt";//[localeString UTF8String];                                        //cLocaleFName
    gameArgs[ 5] = [username UTF8String];                                                       //UserNick
    gameArgs[ 6] = [[[self.systemSettings objectForKey:@"sound"] stringValue] UTF8String];      //isSoundEnabled
    gameArgs[ 7] = [[[self.systemSettings objectForKey:@"music"] stringValue] UTF8String];      //isMusicEnabled
    gameArgs[ 8] = [[[self.systemSettings objectForKey:@"alternate"] stringValue] UTF8String];  //cAltDamage
    gameArgs[ 9] = [rotation UTF8String];                                                       //rotateQt
    gameArgs[10] = (self.gameType == gtSave) ? [self.savePath UTF8String] : NULL;               //recordFileName

    [verticalSize release];
    [horizontalSize release];
    [rotation release];
    [localeString release];
    [ipcString release];
    return gameArgs;
}


@end
