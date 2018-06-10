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
#import "MGSplitViewController.h"
#import "SettingsBaseViewController.h"
#import "AboutViewController.h"
#import "SavedGamesViewController.h"
#import "RestoreViewController.h"
#import "MissionTrainingViewController.h"
#import "CampaignsViewController.h"
#import "Appirater.h"
#import "ServerProtocolNetwork.h"
#import "GameInterfaceBridge.h"

#import "SettingsBaseViewController.h"
#import "GeneralSettingsViewController.h"
#import "TeamSettingsViewController.h"
#import "WeaponSettingsViewController.h"
#import "SchemeSettingsViewController.h"
#import "SupportViewController.h"

#ifdef DEBUG
#import "GameLogViewController.h"
#endif

@interface MainMenuViewController ()
@property (retain, nonatomic) IBOutlet UIButton *simpleGameButton;
@property (retain, nonatomic) IBOutlet UIButton *missionsButton;
@property (retain, nonatomic) IBOutlet UIButton *campaignButton;
@end

@implementation MainMenuViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
- (void)viewDidLoad {
    self.view.frame = [[UIScreen mainScreen] safeBounds];
    [super viewDidLoad];
    
    [self.simpleGameButton setTitle:NSLocalizedString(@"Simple", nil) forState:UIControlStateNormal];
    [self.missionsButton setTitle:NSLocalizedString(@"Missions", nil) forState:UIControlStateNormal];
    [self.campaignButton setTitle:NSLocalizedString(@"Campaign", nil) forState:UIControlStateNormal];
    
    [self.simpleGameButton applyDarkBlueQuickStyle];
    [self.missionsButton applyDarkBlueQuickStyle];
    [self.campaignButton applyDarkBlueQuickStyle];
    
    // not yet ready for release...
    [self.campaignButton setHidden:YES];
    
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
        restored.modalPresentationStyle = UIModalPresentationFormSheet;

        [self performSelector:@selector(presentViewController:) withObject:restored afterDelay:0.25];
    }
    else
    {
        // let's not prompt for rating when app crashed >_>
        [Appirater appLaunched:YES];
    }

    /*
    [ServerProtocolNetwork openServerConnection];
    */
}

- (void) presentViewController:(UIViewController *)vc
{
    [self presentViewController:vc animated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [[AudioManagerController mainManager] playBackgroundMusic];
    [super viewWillAppear:animated];
}

#pragma mark -
- (IBAction)switchViews:(id)sender {
    UIButton *button = (UIButton *)sender;
    UIAlertView *alert;
    NSString *xib = nil;

    [[AudioManagerController mainManager] playClickSound];
    switch (button.tag) {
        case 0: {
            xib = IS_IPAD() ? @"GameConfigViewController-iPad" : @"GameConfigViewController-iPhone";

            GameConfigViewController *gcvc = [[GameConfigViewController alloc] initWithNibName:xib bundle:nil];
            gcvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

            [self presentViewController:gcvc animated:YES completion:nil];
            break;
        }
        case 2:
            if (IS_IPAD())
            {
                // the contents on the right of the splitview, setting targetController to nil to avoid creating the table
                SettingsBaseViewController *rightController = [[SettingsBaseViewController alloc] init];
                rightController.targetController = nil;
                UINavigationController *rightNavController = [[UINavigationController alloc] initWithRootViewController:rightController];
                
                // the contens on the left of the splitview, setting targetController that will receive push/pop actions
                SettingsBaseViewController *leftController = [[SettingsBaseViewController alloc] init];
                leftController.targetController = rightNavController.topViewController;
                UINavigationController *leftNavController = [[UINavigationController alloc] initWithRootViewController:leftController];
                
                MGSplitViewController *splitViewRootController = [[MGSplitViewController alloc] init];
                splitViewRootController.delegate = nil;
                splitViewRootController.showsMasterInPortrait = YES;
                splitViewRootController.viewControllers = [NSArray arrayWithObjects:leftNavController, rightNavController, nil];

                [self presentViewController:splitViewRootController animated:YES completion:nil];
            }
            else
            {
                NSMutableArray *tabBarNavigationControllers = [[NSMutableArray alloc] initWithCapacity:5];
                
                UIViewController *generalSettingsViewController = [[GeneralSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                generalSettingsViewController.tabBarItem = [self tabBarItemWithTitle:NSLocalizedString(@"General",@"") imageName:@"flower" selectedImageName:@"flower_filled"];
                UINavigationController *generalNavController = [[UINavigationController alloc] initWithRootViewController:generalSettingsViewController];
                [tabBarNavigationControllers addObject:generalNavController];
                
                UIViewController *teamSettingsViewController = [[TeamSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                teamSettingsViewController.tabBarItem = [self tabBarItemWithTitle:NSLocalizedString(@"Teams",@"") imageName:@"teams" selectedImageName:@"teams_filled"];
                UINavigationController *teamNavController = [[UINavigationController alloc] initWithRootViewController:teamSettingsViewController];
                [tabBarNavigationControllers addObject:teamNavController];
                
                UIViewController *weaponSettingsViewController = [[WeaponSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                weaponSettingsViewController.tabBarItem = [self tabBarItemWithTitle:NSLocalizedString(@"Weapons",@"") imageName:@"bullet" selectedImageName:@"bullet_filled"];
                UINavigationController *weaponNavController = [[UINavigationController alloc] initWithRootViewController:weaponSettingsViewController];
                [tabBarNavigationControllers addObject:weaponNavController];
                
                UIViewController *schemeSettingsViewController = [[SchemeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                schemeSettingsViewController.tabBarItem = [self tabBarItemWithTitle:NSLocalizedString(@"Schemes",@"") imageName:@"target" selectedImageName:@"target_filled"];
                UINavigationController *schemeNavController = [[UINavigationController alloc] initWithRootViewController:schemeSettingsViewController];
                [tabBarNavigationControllers addObject:schemeNavController];
                
                UIViewController *supportViewController = [[SupportViewController alloc] initWithStyle:UITableViewStyleGrouped];
                supportViewController.tabBarItem = [self tabBarItemWithTitle:NSLocalizedString(@"Support",@"") imageName:@"heart" selectedImageName:@"heart_filled"];
                UINavigationController *supportNavController = [[UINavigationController alloc] initWithRootViewController:supportViewController];
                [tabBarNavigationControllers addObject:supportNavController];
                
                UITabBarController *settingsTabController = [[UITabBarController alloc] init];
                settingsTabController.viewControllers = tabBarNavigationControllers;
                
                [self presentViewController:settingsTabController animated:YES completion:nil];
            }
            break;
        case 3:
#ifdef DEBUG
            {
                GameLogViewController *gameLogVC = [[GameLogViewController alloc] init];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:gameLogVC];
                
                [self presentViewController:navController animated:YES completion:nil];
            }
#else
            {
                AboutViewController *about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
                about.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                about.modalPresentationStyle = UIModalPresentationFormSheet;
                
                [self presentViewController:about animated:YES completion:nil];
            }
#endif
            break;
        case 4:
            {
                SavedGamesViewController *savedgames = [[SavedGamesViewController alloc] initWithNibName:@"SavedGamesViewController" bundle:nil];
                savedgames.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                savedgames.modalPresentationStyle = UIModalPresentationPageSheet;
                
                [self presentViewController:savedgames animated:YES completion:nil];
            }
            break;
        case 5:
            {
                xib = IS_IPAD() ? @"MissionTrainingViewController-iPad" : @"MissionTrainingViewController-iPhone";
                MissionTrainingViewController *missions = [[MissionTrainingViewController alloc] initWithNibName:xib bundle:nil];
                missions.modalTransitionStyle = IS_IPAD() ? UIModalTransitionStyleCoverVertical : UIModalTransitionStyleCrossDissolve;
                missions.modalPresentationStyle = UIModalPresentationPageSheet;
                
                [self presentViewController:missions animated:YES completion:nil];
            }
            break;
        case 6: {
            [GameInterfaceBridge registerCallingController:self];
            [GameInterfaceBridge startSimpleGame];
            break;
        }
        case 7:
            {
                xib = IS_IPAD() ? @"CampaignsViewController-iPad" : @"CampaignsViewController-iPhone";
                CampaignsViewController *campaigns = [[CampaignsViewController alloc] initWithNibName:xib bundle:nil];
                UINavigationController *campaignNavigationController = [[UINavigationController alloc] initWithRootViewController:campaigns];
                
                campaignNavigationController.modalTransitionStyle = IS_IPAD() ? UIModalTransitionStyleCoverVertical : UIModalTransitionStyleCrossDissolve;
                campaignNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
                
                [self presentViewController:campaignNavigationController animated:YES completion:nil];
            }
            break;
        default: {
            alert = [[UIAlertView alloc] initWithTitle:@"Not Yet Implemented"
                                               message:@"Sorry, this feature is not yet implemented"
                                              delegate:nil
                                     cancelButtonTitle:@"Well, don't worry"
                                     otherButtonTitles:nil];
            [alert show];
            break;
        }
    }
}

- (UITabBarItem *)tabBarItemWithTitle: (NSString *)title
                            imageName: (NSString *)imageName
                    selectedImageName: (NSString *)selectedImageName
{
    return [[UITabBarItem alloc] initWithTitle:title
                                          image:[UIImage imageNamed:imageName]
                                  selectedImage:[UIImage imageNamed:selectedImageName]];
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

@end
