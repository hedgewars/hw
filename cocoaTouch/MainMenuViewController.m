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
@synthesize cover, versionLabel;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
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
    
    // create a team
    createTeamNamed(@"Default Team");
    
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
	[NSThread exit];
}

#pragma mark -
-(void) appear {
    [[SDLUIKitDelegate sharedAppDelegate].uiwindow addSubview:self.view];
    [self release];
    
    [UIView beginAnimations:@"inserting main controller" context:NULL];
	[UIView setAnimationDuration:1];
	self.view.alpha = 1;
	[UIView commitAnimations];
    
    [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(hideBehind) userInfo:nil repeats:NO];
}

-(void) disappear {
    if (nil != cover)
        [cover release];
    
    [UIView beginAnimations:@"removing main controller" context:NULL];
	[UIView setAnimationDuration:1];
	self.view.alpha = 0;
	[UIView commitAnimations];
    [self retain];
    //[self.view removeFromSuperview];
}

// this is a silly way to hide the sdl contex that remained active
-(void) hideBehind {
    if (nil == cover) {
        cover= [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        cover.backgroundColor = [UIColor blackColor];
    }
    [[SDLUIKitDelegate sharedAppDelegate].uiwindow insertSubview:cover belowSubview:self.view];
}

#pragma mark -
-(IBAction) switchViews:(id) sender {
    UIButton *button = (UIButton *)sender;
    UIAlertView *alert;
    NSString *configNibName;
    
    switch (button.tag) {
        case 0:
            if (1) { // bug in UIModalTransitionStylePartialCurl?
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    configNibName = @"GameConfigViewController-iPad";
                else
                    configNibName = @"GameConfigViewController-iPhone";

                gameConfigViewController = [[GameConfigViewController alloc] initWithNibName:configNibName
                                                                                      bundle:nil];
#ifdef __IPHONE_3_2
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    gameConfigViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
#endif
            }
            
            [self presentModalViewController:gameConfigViewController animated:YES];
            break;
        case 2:
            if (nil == splitRootViewController) {
                splitRootViewController = [[SplitViewRootController alloc] initWithNibName:nil bundle:nil];
                splitRootViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            }
            
            [self presentModalViewController:splitRootViewController animated:YES];
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
    self.cover = nil;
    self.versionLabel = nil;
    gameConfigViewController = nil;
    splitRootViewController = nil;
	[super viewDidUnload];
}

-(void) dealloc {
    [versionLabel release];
    [cover release];
    [splitRootViewController release];
    [gameConfigViewController release];
	[super dealloc];
}

@end
