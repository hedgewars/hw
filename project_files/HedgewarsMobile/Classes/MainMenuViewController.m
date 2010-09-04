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
    self.versionLabel.text = @"";//versionNumber;
    [versionNumber release];

    // listen to request to remove the modalviewcontroller
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissModalViewController)
                                                 name: @"dismissModalView"
                                               object:nil];
    
    // now check if some configuration files are already set; if they are present it means that the current copy must be updated
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
