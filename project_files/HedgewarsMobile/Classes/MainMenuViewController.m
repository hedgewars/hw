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


#import "MainMenuViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GameConfigViewController.h"
#import "SettingsContainerViewController.h"
#import "AboutViewController.h"
#import "SavedGamesViewController.h"
#import "RestoreViewController.h"
#import "MissionTrainingViewController.h"
#import "Appirater.h"
#import "ServerProtocolNetwork.h"
#import "GameInterfaceBridge.h"

#ifdef DEBUG
#import "GameLogViewController.h"
#endif

@interface MainMenuViewController ()
@property (retain, nonatomic) IBOutlet UIButton *simpleGameButton;
@property (retain, nonatomic) IBOutlet UIButton *missionsButton;
@end

@implementation MainMenuViewController

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
-(void) viewDidLoad {
    self.view.frame = [[UIScreen mainScreen] safeBounds];
    [super viewDidLoad];
    
    [self.simpleGameButton applyDarkBlueQuickStyle];
    [self.missionsButton applyDarkBlueQuickStyle];
    
    // get the app's version
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];

    // get the version number that we've been tracking
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *trackingVersion = [userDefaults stringForKey:@"HedgeVersion"];

    if (trackingVersion == nil || [trackingVersion isEqualToString:version] == NO) {
        // remove any reminder of previous games as saves are going to be wiped out
        [userDefaults setObject:@"" forKey:@"savedGamePath"];
        // update the tracking version with the new one
        [userDefaults setObject:version forKey:@"HedgeVersion"];
        [userDefaults synchronize];

        [CreationChamber createFirstLaunch];
    }

    // prompt for restoring any previous game
    NSString *saveString = [userDefaults objectForKey:@"savedGamePath"];
    if (saveString != nil && [saveString isEqualToString:@""] == NO && [[userDefaults objectForKey:@"saveIsValid"] boolValue])
    {
        NSString *xibName = [@"RestoreViewController-" stringByAppendingString:(IS_IPAD() ? @"iPad" : @"iPhone")];
        RestoreViewController *restored = [[RestoreViewController alloc] initWithNibName:xibName bundle:nil];
        if ([restored respondsToSelector:@selector(setModalPresentationStyle:)])
            restored.modalPresentationStyle = UIModalPresentationFormSheet;

        [self performSelector:@selector(presentViewController:) withObject:restored afterDelay:0.25];
    }
    else
    {
        // let's not prompt for rating when app crashed >_>
        [Appirater appLaunched];
    }

    /*
    [ServerProtocolNetwork openServerConnection];
    */
}

- (void) presentViewController:(UIViewController *)vc
{
    [self presentViewController:vc animated:NO completion:nil];
    [vc release];
}

-(void) viewWillAppear:(BOOL)animated {
    [[AudioManagerController mainManager] playBackgroundMusic];
    [super viewWillAppear:animated];
}

#pragma mark -
-(IBAction) switchViews:(id) sender {
    UIButton *button = (UIButton *)sender;
    UIAlertView *alert;
    NSString *xib = nil;

    [[AudioManagerController mainManager] playClickSound];
    switch (button.tag) {
        case 0:
            xib = IS_IPAD() ? @"GameConfigViewController-iPad" : @"GameConfigViewController-iPhone";

            GameConfigViewController *gcvc = [[GameConfigViewController alloc] initWithNibName:xib bundle:nil];
            gcvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

            [self presentViewController:gcvc animated:YES completion:nil];
            [gcvc release];
            break;
        case 2:
            {
                SettingsContainerViewController *svrc = [[SettingsContainerViewController alloc] initWithNibName:nil bundle:nil];
                svrc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

                [self presentViewController:svrc animated:YES completion:nil];
                [svrc release];
            }
            break;
        case 3:
#ifdef DEBUG
            {
                GameLogViewController *gameLogVC = [[GameLogViewController alloc] init];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:gameLogVC];
                [gameLogVC release];
                
                [self presentViewController:navController animated:YES completion:nil];
                [navController release];
            }
#else
            {
                AboutViewController *about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
                about.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                if ([about respondsToSelector:@selector(setModalPresentationStyle:)])
                     about.modalPresentationStyle = UIModalPresentationFormSheet;
                
                [self presentViewController:about animated:YES completion:nil];
                [about release];
            }
#endif
            break;
        case 4:
            {
                SavedGamesViewController *savedgames = [[SavedGamesViewController alloc] initWithNibName:@"SavedGamesViewController" bundle:nil];
                savedgames.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                if ([savedgames respondsToSelector:@selector(setModalPresentationStyle:)])
                    savedgames.modalPresentationStyle = UIModalPresentationPageSheet;
                
                [self presentViewController:savedgames animated:YES completion:nil];
                [savedgames release];
            }
            break;
        case 5:
            {
                xib = IS_IPAD() ? @"MissionTrainingViewController-iPad" : @"MissionTrainingViewController-iPhone";
                MissionTrainingViewController *missions = [[MissionTrainingViewController alloc] initWithNibName:xib bundle:nil];
                missions.modalTransitionStyle = IS_IPAD() ? UIModalTransitionStyleCoverVertical : UIModalTransitionStyleCrossDissolve;
                if ([missions respondsToSelector:@selector(setModalPresentationStyle:)])
                    missions.modalPresentationStyle = UIModalPresentationPageSheet;
                
                [self presentViewController:missions animated:YES completion:nil];
                [missions release];
            }
            break;
        case 6:
            [GameInterfaceBridge registerCallingController:self];
            [GameInterfaceBridge startSimpleGame];
            break;
        default:
            alert = [[UIAlertView alloc] initWithTitle:@"Not Yet Implemented"
                                               message:@"Sorry, this feature is not yet implemented"
                                              delegate:nil
                                     cancelButtonTitle:@"Well, don't worry"
                                     otherButtonTitles:nil];
            [alert show];
            [alert release];
            break;
    }
}

#pragma mark -
-(void) viewDidUnload {
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) didReceiveMemoryWarning {
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) dealloc {
    [_simpleGameButton release];
    [_missionsButton release];
    [super dealloc];
}

@end
