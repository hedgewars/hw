/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * File created on 08/01/2010.
 */


#import "MainMenuViewController.h"
#import "CommodityFunctions.h"
#import "SDL_uikitappdelegate.h"
#import "SDL_mixer.h"
#import "PascalImports.h"
#import "GameConfigViewController.h"
#import "SplitViewRootController.h"
#import "AboutViewController.h"

@implementation MainMenuViewController
@synthesize versionLabel, gameConfigViewController, settingsViewController, aboutViewController;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    if (self.settingsViewController.view.superview == nil)
        self.settingsViewController = nil;
    if (self.gameConfigViewController.view.superview == nil)
        self.gameConfigViewController = nil;
    MSG_MEMCLEAN();
}

// using a different thread for audio 'cos it's slow
-(void) initAudioThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // do somthing in the future
    [pool release];
}

// check if some configuration files are already set; if they are present it means that the current copy must be updated
-(void) createNecessaryFiles {
    BOOL doCreateFiles = NO;
    NSString *resDir = [[NSBundle mainBundle] resourcePath];
    
    NSString *versionFileToCheck = [NSString stringWithFormat:@"%@/version.txt",DOCUMENTS_FOLDER()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:versionFileToCheck]) {
        NSString *currentVersion = [NSString stringWithContentsOfFile:versionFileToCheck encoding:NSUTF8StringEncoding error:nil];
        NSString *newVersion = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/Settings/version.txt",resDir] encoding:NSUTF8StringEncoding error:nil];
        if ([currentVersion intValue] < [newVersion intValue]) {
            doCreateFiles = YES;
            [newVersion writeToFile:versionFileToCheck atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    } else {
        doCreateFiles = YES;
        [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/Settings/version.txt",resDir] toPath:versionFileToCheck error:nil];
    } 

    
    if (doCreateFiles == YES) {
        NSError *err = nil;
        NSString *directoryToCheck, *fileToCheck, *fileToUpdate;
        DLog(@"Creating necessary files");
        
        // if the settings file is already present, we merge current preferences with the update
        directoryToCheck = [NSString stringWithFormat:@"%@/Settings/settings.plist",resDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:SETTINGS_FILE()]) {
            NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_FILE()];
            NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithContentsOfFile:directoryToCheck];
            [update addEntriesFromDictionary:settings];
            [settings release];
            [update writeToFile:SETTINGS_FILE() atomically:YES];
            [update release];
        } else 
            [[NSFileManager defaultManager] copyItemAtPath:directoryToCheck toPath:SETTINGS_FILE() error:&err];
        
        // if the teams are already present we merge the old teams if they still exist
        directoryToCheck = [NSString stringWithFormat:@"%@/Settings/Teams",resDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:TEAMS_DIRECTORY()]) {
            for (NSString *str in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryToCheck error:nil]) {
                fileToCheck = [NSString stringWithFormat:@"%@/%@",TEAMS_DIRECTORY(),str];
                fileToUpdate = [NSString stringWithFormat:@"%@/Settings/Teams/%@",resDir,str];
                if ([[NSFileManager defaultManager] fileExistsAtPath:fileToCheck]) {
                    NSDictionary *team = [[NSDictionary alloc] initWithContentsOfFile:fileToCheck];
                    NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithContentsOfFile:fileToUpdate];
                    [update addEntriesFromDictionary:team];
                    [team release];
                    [update writeToFile:fileToCheck atomically:YES];
                    [update release];
                }
            }
        } else
            [[NSFileManager defaultManager] copyItemAtPath:directoryToCheck toPath:TEAMS_DIRECTORY() error:&err];

        // the same holds for schemes (but they're arrays)
        directoryToCheck = [NSString stringWithFormat:@"%@/Settings/Schemes",resDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:SCHEMES_DIRECTORY()]) {
            for (NSString *str in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryToCheck error:nil]) {
                fileToCheck = [NSString stringWithFormat:@"%@/%@",SCHEMES_DIRECTORY(),str];
                fileToUpdate = [NSString stringWithFormat:@"%@/Settings/Schemes/%@",resDir,str];
                if ([[NSFileManager defaultManager] fileExistsAtPath:fileToCheck]) {
                    NSArray *scheme = [[NSArray alloc] initWithContentsOfFile:fileToCheck];
                    NSArray *update = [[NSArray alloc] initWithContentsOfFile:fileToUpdate];
                    if ([update count] > [scheme count])
                        [update writeToFile:fileToCheck atomically:YES];
                    [update release];
                    [scheme release];
                }
            }
        } else
            [[NSFileManager defaultManager] copyItemAtPath:directoryToCheck toPath:SCHEMES_DIRECTORY() error:&err];
        
        // we create weapons the first time only, they are autoupdated each time
        if ([[NSFileManager defaultManager] fileExistsAtPath:WEAPONS_DIRECTORY()] == NO) {
            [[NSFileManager defaultManager] createDirectoryAtPath:WEAPONS_DIRECTORY()
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&err];
            createWeaponNamed(@"Default", 0);
            createWeaponNamed(@"Crazy", 1);
            createWeaponNamed(@"Pro mode", 2);
            createWeaponNamed(@"Shoppa", 3);
            createWeaponNamed(@"Basketball", 4);
            createWeaponNamed(@"Minefield", 5);
        }
        
        DLog(@"Success");
        
        if (err != nil) 
            DLog(@"%@", err);
    }
}

/* // ask the user to leave a review for this app
-(void) reviewCounter {
    CGFloat reviewInt = [[NSUserDefaults standardUserDefaults] integerForKey: @"intValueKey"];
    
    if (reviewInt) {
        reviewInt++;
        [[NSUserDefaults standardUserDefaults] setInteger:reviewInt forKey:@"intValueKey"];
    } else {
        CGFloat start = 1;
        NSUserDefaults *reviewPrefs = [NSUserDefaults standardUserDefaults];
        [reviewPrefs setInteger:start forKey: @"intValueKey"];
        [reviewPrefs synchronize]; // writes modifications to disk
    }
    
    if (1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mabuhay!"
                                                        message:@"Looks like you Enjoy using this app. Could you spare a moment of your time to review it in the AppStore?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles: @"OK, I'll Review It Now", @"Remind Me Later", @"Don't Remind Me", nil];
        [alert show]; 
        [alert release];
        
        reviewInt++;
        
        [[NSUserDefaults standardUserDefaults] setInteger:reviewInt forKey:@"intValueKey"];
    }
}

#pragma mark -
#pragma mark alert view delegate
-(void) alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger) buttonIndex {
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0) {
        NSString *str = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa";
        str = [NSString stringWithFormat:@"%@/wa/viewContentsUserReviews?", str]; 
        str = [NSString stringWithFormat:@"%@type=Vittorio+Giovara&id=", str];
        
        // Here is the app id from itunesconnect
        str = [NSString stringWithFormat:@"%@391234866", str]; 
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=391234866&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]]; 
    } else if (buttonIndex == 1) {
        int startAgain = 0;
        [[NSUserDefaults standardUserDefaults] setInteger:startAgain forKey:@"intValueKey"];
        
    } else if (buttonIndex == 2) { 
        int neverRemind = 4;
        [[NSUserDefaults standardUserDefaults] setInteger:neverRemind forKey:@"intValueKey"];
    }
} */

#pragma mark -
-(void) viewDidLoad {
    [NSThread detachNewThreadSelector:@selector(initAudioThread)
                             toTarget:self
                           withObject:nil];

    char *ver;
    HW_versionInfo(NULL, &ver);
    NSString *versionNumber = [[NSString alloc] initWithCString:ver];
    self.versionLabel.text = @"";//versionNumber;
    [versionNumber release];

    // listen to request to remove the modalviewcontroller
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissModalViewController)
                                                 name: @"dismissModalView"
                                               object:nil];

    [self createNecessaryFiles];
    
    [super viewDidLoad];
}


#pragma mark -
-(IBAction) switchViews:(id) sender {
    UIButton *button = (UIButton *)sender;
    UIAlertView *alert;
    NSString *xib;

    playSound(@"clickSound");
    switch (button.tag) {
        case 0:
            if (nil == self.gameConfigViewController) {
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    xib = nil;
                else
                    xib = @"GameConfigViewController";
                
                GameConfigViewController *gcvc = [[GameConfigViewController alloc] initWithNibName:xib bundle:nil];
                gcvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                self.gameConfigViewController = gcvc;
                [gcvc release];
            }

            [self presentModalViewController:self.gameConfigViewController animated:YES];
            break;
        case 2:
            if (nil == self.settingsViewController) {
                SplitViewRootController *svrc = [[SplitViewRootController alloc] initWithNibName:nil bundle:nil];
                svrc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                self.settingsViewController = svrc;
                [svrc release];
            }

            [self presentModalViewController:self.settingsViewController animated:YES];
            break;
        case 3:
            if (nil == self.aboutViewController) {
                AboutViewController *about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
                about.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                about.modalPresentationStyle = UIModalPresentationFormSheet;
                self.aboutViewController = about;
                [about release];
            }
            
            [self presentModalViewController:self.aboutViewController animated:YES];
            /*
            debugStr = [[NSString alloc] initWithContentsOfFile:DEBUG_FILE()];
            UITextView *scroll = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
            scroll.text = debugStr;
            [debugStr release];
            scroll.editable = NO;

            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn addTarget:scroll action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
            btn.backgroundColor = [UIColor blackColor];
            btn.frame = CGRectMake(self.view.frame.size.height-70, 0, 70, 70);
            [scroll addSubview:btn];
            [self.view addSubview:scroll];
            [scroll release];
            */
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

// must be kept for compatibility with the settings page
-(void) dismissModalViewController {
    [self dismissModalViewControllerAnimated:YES];
}

-(void) viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.versionLabel = nil;
    self.gameConfigViewController = nil;
    self.settingsViewController = nil;
    self.aboutViewController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [versionLabel release];
    [settingsViewController release];
    [gameConfigViewController release];
    [aboutViewController release];
    [super dealloc];
}

@end
