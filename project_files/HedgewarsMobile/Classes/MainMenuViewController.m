//
//  MainMenuViewController.m
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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

-(void) viewDidLoad {
    [NSThread detachNewThreadSelector:@selector(initAudioThread)
                             toTarget:self
                           withObject:nil];

    char *ver;
    HW_versionInfo(NULL, &ver);
    NSString *versionNumber = [[NSString alloc] initWithCString:ver];
    self.versionLabel.text = versionNumber;
    [versionNumber release];

    // listen to request to remove the modalviewcontroller
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissModalViewController)
                                                 name: @"dismissModalView"
                                               object:nil];
    
    // now check if some configuration files are already set; if they are present it means that the current copy must be updated
    NSError *err = nil;
    NSString *fileToCheck, *teamToCheck, *teamToUpdate, *schemeToCheck, *schemeToUpdate;
    NSString *resDir = [[NSBundle mainBundle] resourcePath];
    
    NSString *dirToCheck = [NSString stringWithFormat:@"%@/Settings/", resDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dirToCheck] == YES) {

        // if the settings file is already present, we merge current preferences with the update
        fileToCheck = [NSString stringWithFormat:@"%@/Settings/settings.plist",resDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:SETTINGS_FILE()]) {
            NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_FILE()];
            NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithContentsOfFile:fileToCheck];
            [update addEntriesFromDictionary:settings];
            [settings release];
            [update writeToFile:SETTINGS_FILE() atomically:YES];
            [update release];
        } else 
            [[NSFileManager defaultManager] copyItemAtPath:fileToCheck toPath:SETTINGS_FILE() error:&err];
        
        // if the teams are already present we merge the old teams if they still exist
        fileToCheck = [NSString stringWithFormat:@"%@/Settings/Teams",resDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:TEAMS_DIRECTORY()]) {
            for (NSString *str in [[NSFileManager defaultManager] contentsAtPath:fileToCheck]) {
                teamToCheck = [NSString stringWithFormat:@"%@/%@",TEAMS_DIRECTORY(),str];
                teamToUpdate = [NSString stringWithFormat:@"%@/Settings/Teams/%@",resDir,str];
                if ([[NSFileManager defaultManager] fileExistsAtPath:teamToCheck]) {
                    NSDictionary *team = [[NSDictionary alloc] initWithContentsOfFile:teamToCheck];
                    NSMutableDictionary *update = [[NSMutableDictionary alloc] initWithContentsOfFile:teamToUpdate];
                    [update addEntriesFromDictionary:team];
                    [team release];
                    [update writeToFile:teamToCheck atomically:YES];
                    [update release];
                }
            }
        } else
            [[NSFileManager defaultManager] copyItemAtPath:fileToCheck toPath:TEAMS_DIRECTORY() error:&err];

        // the same holds for schemes (but they're arrays)
        fileToCheck = [NSString stringWithFormat:@"%@/Settings/Schemes",resDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:SCHEMES_DIRECTORY()]) {
            for (NSString *str in [[NSFileManager defaultManager] contentsAtPath:fileToCheck]) {
                schemeToCheck = [NSString stringWithFormat:@"%@/%@",SCHEMES_DIRECTORY(),str];
                schemeToUpdate = [NSString stringWithFormat:@"%@/Settings/Schemes/%@",resDir,str];
                if ([[NSFileManager defaultManager] fileExistsAtPath:schemeToCheck]) {
                    NSArray *scheme = [[NSArray alloc] initWithContentsOfFile:schemeToCheck];
                    NSArray *update = [[NSArray alloc] initWithContentsOfFile:schemeToUpdate];
                    if ([update count] > [scheme count])
                        [update writeToFile:schemeToCheck atomically:YES];
                    [update release];
                    [scheme release];
                }
            }
        } else
            [[NSFileManager defaultManager] copyItemAtPath:fileToCheck toPath:SCHEMES_DIRECTORY() error:&err];
        
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
        
        // clean this dir so that it doesn't get called again
        [[NSFileManager defaultManager] removeItemAtPath:dirToCheck error:&err];
        if (err != nil) 
            DLog(@"%@", err);
    }
    
    [super viewDidLoad];
}


#pragma mark -
-(IBAction) switchViews:(id) sender {
    UIButton *button = (UIButton *)sender;
    UIAlertView *alert;
    NSString *xib;

    switch (button.tag) {
        case 0:
            if (nil == self.gameConfigViewController) {
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    xib = nil;
                else
                    xib = @"GameConfigViewController";
                
                GameConfigViewController *gcvc = [[GameConfigViewController alloc] initWithNibName:xib bundle:nil];
                self.gameConfigViewController = gcvc;
                [gcvc release];
            }

            [self presentModalViewController:self.gameConfigViewController animated:YES];
            break;
        case 2:
            if (nil == self.settingsViewController) {
                SplitViewRootController *svrc = [[SplitViewRootController alloc] initWithNibName:nil bundle:nil];
                svrc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                self.settingsViewController = svrc;
                [svrc release];
            }

            [self presentModalViewController:self.settingsViewController animated:YES];
            break;
        case 3:
            if (nil == self.aboutViewController) {
                AboutViewController *about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
                about.modalTransitionStyle = UIModalPresentationFormSheet;
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

// allows child controllers to return to the main controller
-(void) dismissModalViewController {
    [self dismissModalViewControllerAnimated:YES];
}

-(void) viewDidUnload {
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
