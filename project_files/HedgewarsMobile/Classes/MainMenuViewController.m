//
//  MainMenuViewController.m
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainMenuViewController.h"
#import "SDL_uikitappdelegate.h"
#import "PascalImports.h"
#import "GameConfigViewController.h"
#import "SplitViewRootController.h"
#import "CommodityFunctions.h"

@implementation MainMenuViewController
@synthesize versionLabel;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    if (settingsViewController.view.superview == nil) 
        settingsViewController = nil;
    if (gameConfigViewController.view.superview == nil) 
        gameConfigViewController = nil;
    MSG_MEMCLEAN();
}

-(void) viewDidLoad {
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
    
    // initialize some files the first time we load the game
    if (!([[NSFileManager defaultManager] fileExistsAtPath:SETTINGS_FILE()])) 
        [NSThread detachNewThreadSelector:@selector(checkFirstRun) toTarget:self withObject:nil];
    
    [super viewDidLoad];
}

// this is called to verify whether it's the first time the app is launched
// if it is it blocks user interaction with an alertView until files are created
-(void) checkFirstRun {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"First time run, creating settings files at %@", SETTINGS_FILE());
    
    // show a popup with an indicator to make the user wait
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please wait",@"")
                                                    message:nil
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
    [alert show];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] 
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(alert.bounds.size.width / 2, alert.bounds.size.height - 50);
    [indicator startAnimating];
    [alert addSubview:indicator];
    [indicator release];
    
    // create default files (teams/weapons/scheme)
    createTeamNamed(@"Pirates");
    createTeamNamed(@"Ninjas");
    createWeaponNamed(@"Default");
    createSchemeNamed(@"Default");
    
    // create settings.plist
    NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] init];

    [saveDict setObject:@"" forKey:@"username"];
    [saveDict setObject:@"" forKey:@"password"];
    [saveDict setObject:[NSNumber numberWithBool:YES] forKey:@"music"];
    [saveDict setObject:[NSNumber numberWithBool:YES] forKey:@"sound"];
    [saveDict setObject:[NSNumber numberWithBool:NO] forKey:@"alternate"];

    [saveDict writeToFile:SETTINGS_FILE() atomically:YES];
    [saveDict release];    
    
    // ok let the user take control
    [alert dismissWithClickedButtonIndex:0 animated:YES];
    [alert release];

    [pool release];

    // TODO: instead of this useless runtime initialization, check that all ammos remain compatible with engine
}

#pragma mark -
-(IBAction) switchViews:(id) sender {
    UIButton *button = (UIButton *)sender;
    UIAlertView *alert;
    NSString *debugStr;

    switch (button.tag) {
        case 0:
            gameConfigViewController = [[GameConfigViewController alloc] initWithNibName:@"GameConfigViewController" bundle:nil];        

            [self presentModalViewController:gameConfigViewController animated:YES];
            break;
        case 2:
            if (nil == settingsViewController) {
                settingsViewController = [[SplitViewRootController alloc] initWithNibName:nil bundle:nil];
                settingsViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            }
            
            [self presentModalViewController:settingsViewController animated:YES];
            break;
        case 3:
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
    gameConfigViewController = nil;
    settingsViewController = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}

-(void) dealloc {
    [versionLabel release];
    [settingsViewController release];
    [gameConfigViewController release];
    [super dealloc];
}

@end
