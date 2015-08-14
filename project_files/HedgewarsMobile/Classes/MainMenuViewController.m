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


@implementation MainMenuViewController
@synthesize gameConfigViewController, settingsViewController, aboutViewController, savedGamesViewController,
            restoreViewController, missionsViewController;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
-(void) viewDidLoad {
    self.view.frame = [[UIScreen mainScreen] safeBounds];
    [super viewDidLoad];

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

//    // prompt for restoring any previous game
//    NSString *saveString = [userDefaults objectForKey:@"savedGamePath"];
//    if (saveString != nil && [saveString isEqualToString:@""] == NO && [[userDefaults objectForKey:@"saveIsValid"] boolValue]) {
//        if (self.restoreViewController == nil) {
//            NSString *xibName = [@"RestoreViewController-" stringByAppendingString:(IS_IPAD() ? @"iPad" : @"iPhone")];
//            RestoreViewController *restored = [[RestoreViewController alloc] initWithNibName:xibName bundle:nil];
//            if ([restored respondsToSelector:@selector(setModalPresentationStyle:)])
//                restored.modalPresentationStyle = UIModalPresentationFormSheet;
//            self.restoreViewController = restored;
//            [restored release];
//        }
//        [self performSelector:@selector(presentModalViewController:animated:) withObject:self.restoreViewController afterDelay:0.25];
//    } else {
//        // let's not prompt for rating when app crashed >_>
//        [Appirater appLaunched];
//    }

    /*
    [ServerProtocolNetwork openServerConnection];
    */
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
    NSString *debugStr = nil;

    [[AudioManagerController mainManager] playClickSound];
    switch (button.tag) {
        case 0:
            if (nil == self.gameConfigViewController) {
                xib = IS_IPAD() ? @"GameConfigViewController-iPad" : @"GameConfigViewController-iPhone";

                GameConfigViewController *gcvc = [[GameConfigViewController alloc] initWithNibName:xib bundle:nil];
                gcvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                self.gameConfigViewController = gcvc;
                [gcvc release];
            }
            [self presentViewController:self.gameConfigViewController animated:YES completion:nil];
            break;
        case 2:
            if (nil == self.settingsViewController) {
                SettingsContainerViewController *svrc = [[SettingsContainerViewController alloc] initWithNibName:nil bundle:nil];
                svrc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                self.settingsViewController = svrc;
                [svrc release];
            }
            [self presentViewController:self.settingsViewController animated:YES completion:nil];
            break;
        case 3:
#ifdef DEBUG
            if ([[NSFileManager defaultManager] fileExistsAtPath:DEBUG_FILE()])
                debugStr = [[NSString alloc] initWithContentsOfFile:DEBUG_FILE()];
            else
                debugStr = [[NSString alloc] initWithString:@"Here be log"];
            UITextView *scroll = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
            scroll.text = debugStr;
            [debugStr release];
            scroll.editable = NO;
            scroll.alpha = 0;

            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn addTarget:scroll action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:btn action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
            btn.frame = CGRectMake(self.view.frame.size.height-58, -6, 64, 64);
            btn.backgroundColor = [UIColor blackColor];
            btn.titleLabel.textColor = [UIColor whiteColor];
            btn.titleLabel.textAlignment = UITextAlignmentCenter;
            btn.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
            [btn setTitle:@"Close" forState:UIControlStateNormal];
            btn.alpha = 0;
            [btn.layer setCornerRadius:10.0f];
            [btn.layer setMasksToBounds:YES];

            [self.view addSubview:scroll];
            [self.view addSubview:btn];

            [UIView beginAnimations:@"fadein" context:NULL];
            [UIView setAnimationDuration:0.25f];
            btn.alpha = 1;
            scroll.alpha = 1;
            [UIView commitAnimations];
            [scroll release];
#else
            debugStr = debugStr; // prevent compiler warning
            if (nil == self.aboutViewController) {
                AboutViewController *about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
                about.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                if ([about respondsToSelector:@selector(setModalPresentationStyle:)])
                     about.modalPresentationStyle = UIModalPresentationFormSheet;
                self.aboutViewController = about;
                [about release];
            }
            [self presentViewController:self.aboutViewController animated:YES completion:nil];
#endif
            break;
        case 4:
            if (nil == self.savedGamesViewController) {
                SavedGamesViewController *savedgames = [[SavedGamesViewController alloc] initWithNibName:@"SavedGamesViewController" bundle:nil];
                savedgames.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                if ([savedgames respondsToSelector:@selector(setModalPresentationStyle:)])
                    savedgames.modalPresentationStyle = UIModalPresentationPageSheet;
                self.savedGamesViewController = savedgames;
                [savedgames release];
            }
            [self presentViewController:self.savedGamesViewController animated:YES completion:nil];
            break;
        case 5:
            if (nil == self.missionsViewController) {
                xib = IS_IPAD() ? @"MissionTrainingViewController-iPad" : @"MissionTrainingViewController-iPhone";
                MissionTrainingViewController *missions = [[MissionTrainingViewController alloc] initWithNibName:xib bundle:nil];
                missions.modalTransitionStyle = IS_IPAD() ? UIModalTransitionStyleCoverVertical : UIModalTransitionStyleCrossDissolve;
                if ([missions respondsToSelector:@selector(setModalPresentationStyle:)])
                    missions.modalPresentationStyle = UIModalPresentationPageSheet;
                self.missionsViewController = missions;
                [missions release];
            }
            [self presentViewController:self.missionsViewController animated:YES completion:nil];
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
    self.gameConfigViewController = nil;
    self.settingsViewController = nil;
    self.aboutViewController = nil;
    self.savedGamesViewController = nil;
    self.restoreViewController = nil;
    self.missionsViewController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) didReceiveMemoryWarning {
    if (self.settingsViewController.view.superview == nil)
        self.settingsViewController = nil;
    if (self.gameConfigViewController.view.superview == nil)
        self.gameConfigViewController = nil;
    if (self.aboutViewController.view.superview == nil)
        self.aboutViewController = nil;
    if (self.savedGamesViewController.view.superview == nil)
        self.savedGamesViewController = nil;
    if (self.restoreViewController.view.superview == nil)
        self.restoreViewController = nil;
    if (self.missionsViewController.view.superview == nil)
        self.missionsViewController = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) dealloc {
    releaseAndNil(settingsViewController);
    releaseAndNil(gameConfigViewController);
    releaseAndNil(aboutViewController);
    releaseAndNil(savedGamesViewController);
    releaseAndNil(restoreViewController);
    releaseAndNil(missionsViewController);
    [super dealloc];
}

@end
