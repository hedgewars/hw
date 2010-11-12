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
#import "CreationChamber.h"
#import "SDL_uikitappdelegate.h"
#import "PascalImports.h"
#import "GameConfigViewController.h"
#import "SplitViewRootController.h"
#import "AboutViewController.h"
#import "SavedGamesViewController.h"

@implementation MainMenuViewController
@synthesize gameConfigViewController, settingsViewController, aboutViewController, savedGamesViewController;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

// check if some configuration files are already set; if they are present it means that the current copy must be updated
-(void) createNecessaryFiles {
    NSString *sourceFile, *destinationFile;
    NSString *resourcesDir = [[NSBundle mainBundle] resourcePath];
    DLog(@"Creating necessary files");
    
    // SAVES - just delete and overwrite
    if ([[NSFileManager defaultManager] fileExistsAtPath:SAVES_DIRECTORY()])
        [[NSFileManager defaultManager] removeItemAtPath:SAVES_DIRECTORY() error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:SAVES_DIRECTORY() withIntermediateDirectories:NO attributes:nil error:NULL];
    
    // SETTINGS FILE - merge when present
    NSString *baseSettingsFile = [[NSString alloc] initWithFormat:@"%@/Settings/settings.plist",resourcesDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:SETTINGS_FILE()]) {
        NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_FILE()];
        NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithContentsOfFile:baseSettingsFile];
        // the order of what adds what is important
        [update addEntriesFromDictionary:settings];
        [settings release];
        [update writeToFile:SETTINGS_FILE() atomically:YES];
        [update release];
    } else 
        [[NSFileManager defaultManager] copyItemAtPath:baseSettingsFile toPath:SETTINGS_FILE() error:NULL];
    [baseSettingsFile release];

    // TEAMS - update exisiting teams with new format
    if ([[NSFileManager defaultManager] fileExistsAtPath:TEAMS_DIRECTORY()] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:TEAMS_DIRECTORY()
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
        // we copy teams only the first time because it's unlikely that newer ones are going to be added
        NSString *baseTeamsDir = [[NSString alloc] initWithFormat:@"%@/Settings/Teams/",resourcesDir];
        for (NSString *str in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseTeamsDir error:NULL]) {
            sourceFile = [baseTeamsDir stringByAppendingString:str];
            destinationFile = [TEAMS_DIRECTORY() stringByAppendingString:str];
            [[NSFileManager defaultManager] removeItemAtPath:destinationFile error:NULL];
            [[NSFileManager defaultManager] copyItemAtPath:sourceFile toPath:destinationFile error:NULL];
        }
        [baseTeamsDir release];
    }
    // TODO: is merge needed?

    // SCHEMES - update old stuff and add new stuff
    if ([[NSFileManager defaultManager] fileExistsAtPath:SCHEMES_DIRECTORY()] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath:SCHEMES_DIRECTORY()
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    // TODO: do the merge if necessary
    // we overwrite the default ones because it is likely that new modes are added every release
    NSString *baseSchemesDir = [[NSString alloc] initWithFormat:@"%@/Settings/Schemes/",resourcesDir];
    for (NSString *str in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseSchemesDir error:NULL]) {
        sourceFile = [baseSchemesDir stringByAppendingString:str];
        destinationFile = [SCHEMES_DIRECTORY() stringByAppendingString:str];
        [[NSFileManager defaultManager] removeItemAtPath:destinationFile error:NULL];
        [[NSFileManager defaultManager] copyItemAtPath:sourceFile toPath:destinationFile error:NULL];
    }
    [baseSchemesDir release];

    // WEAPONS - always overwrite
    if ([[NSFileManager defaultManager] fileExistsAtPath:WEAPONS_DIRECTORY()] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath:WEAPONS_DIRECTORY()
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    createWeaponNamed(@"Default", 0);
    createWeaponNamed(@"Crazy", 1);
    createWeaponNamed(@"Pro mode", 2);
    createWeaponNamed(@"Shoppa", 3);
    createWeaponNamed(@"Clean slate", 4);
    createWeaponNamed(@"Minefield", 5);
    createWeaponNamed(@"Thinking with Portals", 6);

    DLog(@"Success");
}

#pragma mark -
-(void) viewDidLoad {
    [super viewDidLoad];

    // listen to request to remove the modalviewcontroller (needed due to the splitcontroller)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissModalViewController)
                                                 name: @"dismissModalView"
                                               object:nil];

    // get the app's version
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];

    // get the version number that we've been tracking
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *trackingVersion = [userDefaults stringForKey:@"HedgeVersion"];

    if (trackingVersion == nil || [trackingVersion isEqualToString:version] == NO) {
        [userDefaults setObject:version forKey:@"HedgeVersion"];
        [userDefaults synchronize];
        [self createNecessaryFiles];
    }
}


#pragma mark -
-(IBAction) switchViews:(id) sender {
    UIButton *button = (UIButton *)sender;
    UIAlertView *alert;
    NSString *xib = nil;
    NSString *debugStr = nil;

    playSound(@"clickSound");
    switch (button.tag) {
        case 0:
            if (nil == self.gameConfigViewController) {
                if (IS_IPAD())
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
#ifdef DEBUG
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
#else
            if (nil == self.aboutViewController) {
                AboutViewController *about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
                about.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                about.modalPresentationStyle = UIModalPresentationFormSheet;
                self.aboutViewController = about;
                [about release];
            }
            
            [self presentModalViewController:self.aboutViewController animated:YES];
#endif
            break;
        case 4:
            if (nil == self.savedGamesViewController) {
                SavedGamesViewController *savedgames = [[SavedGamesViewController alloc] initWithNibName:@"SavedGamesViewController" bundle:nil];
                savedgames.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                savedgames.modalPresentationStyle = UIModalPresentationPageSheet;
                self.savedGamesViewController = savedgames;
                [savedgames release];
            }
            
            [self presentModalViewController:self.savedGamesViewController animated:YES];
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
    self.gameConfigViewController = nil;
    self.settingsViewController = nil;
    self.aboutViewController = nil;
    self.savedGamesViewController = nil;
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
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) dealloc {
    [settingsViewController release];
    [gameConfigViewController release];
    [aboutViewController release];
    [savedGamesViewController release];
    [super dealloc];
}

@end
