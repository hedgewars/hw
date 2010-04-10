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
#import "SplitViewRootController.h"
#import "CommodityFunctions.h"

@implementation MainMenuViewController
@synthesize cover, versionLabel;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    self.cover = nil;
    self.versionLabel = nil;
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
    [versionLabel release];
    [cover release];
	[super dealloc];
}

-(void) viewDidUnload {
    self.cover = nil;
	[super viewDidUnload];
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
    NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"];
	if (!([[NSFileManager defaultManager] fileExistsAtPath:filePath])) 
        [NSThread detachNewThreadSelector:@selector(checkFirstRun) toTarget:self withObject:nil];
    
	[super viewDidLoad];
}

// this is called to verify whether it's the first time the app is launched
// if it is it blocks user interaction with an alertView until files are created
-(void) checkFirstRun {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"First time run, creating settings files");
    
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
    [alert release];
    
    // create a team
    createTeamNamed(@"Default Team");
    
    // create settings.plist
    NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] init];

    [saveDict setObject:@"" forKey:@"username"];
    [saveDict setObject:@"" forKey:@"password"];
    [saveDict setObject:[NSNumber numberWithBool:YES] forKey:@"music"];
    [saveDict setObject:[NSNumber numberWithBool:YES] forKey:@"sound"];
    [saveDict setObject:[NSNumber numberWithBool:NO] forKey:@"alternate"];

    NSString *filePath = [[SDLUIKitDelegate sharedAppDelegate] dataFilePath:@"settings.plist"];
    [saveDict writeToFile:filePath atomically:YES];
    [saveDict release];    
    // create other files
    
    // ok let the user take control
    [alert dismissWithClickedButtonIndex:0 animated:YES];

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
    SplitViewRootController *splitViewController;
    UIAlertView *alert;
    
    switch (button.tag) {
        case 0:
            [[SDLUIKitDelegate sharedAppDelegate] startSDLgame];
            break;
        case 2:
            // for now this controller is just to simplify code management
            splitViewController = [[SplitViewRootController alloc] initWithNibName:nil bundle:nil];
            splitViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:splitViewController animated:YES];
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

-(void) dismissModalViewController {
    [self dismissModalViewControllerAnimated:YES];
}

@end
