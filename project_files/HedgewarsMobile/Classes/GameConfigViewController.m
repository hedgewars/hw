    //
//  GameConfigViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 18/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameConfigViewController.h"
#import "SDL_uikitappdelegate.h"
#import "CommodityFunctions.h"
#import "MapConfigViewController.h"
#import "TeamConfigViewController.h"
#import "SchemeWeaponConfigViewController.h"

@implementation GameConfigViewController


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) buttonPressed:(id) sender {
    // works even if it's not actually a button
    UIButton *theButton = (UIButton *)sender;
    switch (theButton.tag) {
        case 0:
            [[self parentViewController] dismissModalViewControllerAnimated:YES];
            break;
        case 1:
            theButton.enabled = NO;
            [self performSelector:@selector(startGame:)
                       withObject:theButton
                       afterDelay:0.25];
            break;
        default:
            break;
    }
}

-(IBAction) segmentPressed:(id) sender {
    UISegmentedControl *theSegment = (UISegmentedControl *)sender;

    switch (theSegment.selectedSegmentIndex) {
        case 0:
            // this init here is just aestetic as this controller was already set up in viewDidLoad
            if (mapConfigViewController == nil) {
                mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPhone" bundle:nil];
            }
            activeController = mapConfigViewController;
            break;
        case 1:
            if (teamConfigViewController == nil) {
                teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
                // this message is compulsory otherwise the table won't be loaded at all
            }
            activeController = teamConfigViewController;
            break;
        case 2:
            if (schemeWeaponConfigViewController == nil) {
                schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
            }
            activeController = schemeWeaponConfigViewController;
            break;
    }
    
    // this message is compulsory otherwise the table won't be loaded at all
    [activeController viewWillAppear:NO];      
    [self.view addSubview:activeController.view];
}

-(void) startGame:(UIButton *)button {
    button.enabled = YES;

    // don't start playing if the preview is in progress
    if ([mapConfigViewController busy]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wait for the Preview",@"")
                                                        message:NSLocalizedString(@"Before playing the preview needs to be generated",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    // play only if there is more than one team
    if ([teamConfigViewController.listOfSelectedTeams count] < 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too few teams playing",@"")
                                                        message:NSLocalizedString(@"You need to select at least two teams to play a game",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    // play if there's room for enough hogs in the selected map
    int hogs = 0;
    for (NSDictionary *teamData in teamConfigViewController.listOfSelectedTeams)
        hogs += [[teamData objectForKey:@"number"] intValue];

    if (hogs > mapConfigViewController.maxHogs) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too many hogs",@"")
                                                        message:NSLocalizedString(@"The map you selected is too small for that many hogs",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    // create the configuration file that is going to be sent to engine
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:mapConfigViewController.seedCommand,@"seed_command",
                                                                      mapConfigViewController.templateFilterCommand,@"templatefilter_command",
                                                                      mapConfigViewController.mapGenCommand,@"mapgen_command",
                                                                      mapConfigViewController.mazeSizeCommand,@"mazesize_command",
                                                                      mapConfigViewController.themeCommand,@"theme_command",
                                                                      teamConfigViewController.listOfSelectedTeams,@"teams_list",
                                                                      schemeWeaponConfigViewController.selectedScheme,@"scheme",
                                                                      schemeWeaponConfigViewController.selectedWeapon,@"weapon",
                                                                      nil];
    [dict writeToFile:GAMECONFIG_FILE() atomically:YES];
    [dict release];

    // finally launch game and remove this controller
    [[self parentViewController] dismissModalViewControllerAnimated:YES];
    [[SDLUIKitDelegate sharedAppDelegate] startSDLgame];
}

-(void) viewDidLoad {
    CGRect screen = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(0, 0, screen.size.height, screen.size.width);

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (mapConfigViewController == nil)
            mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPad" bundle:nil];
        if (teamConfigViewController == nil)
            teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStylePlain];
        teamConfigViewController.view.frame = CGRectMake(0, 224, 300, 500);
        teamConfigViewController.view.backgroundColor = [UIColor clearColor];
        [mapConfigViewController.view addSubview:teamConfigViewController.view];
        if (schemeWeaponConfigViewController == nil)
            schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        schemeWeaponConfigViewController.view.frame = CGRectMake(362, 224, 300, 500);
        schemeWeaponConfigViewController.view.backgroundColor = [UIColor clearColor];
        [mapConfigViewController.view addSubview:schemeWeaponConfigViewController.view];
        for (UIView *oneView in self.view.subviews) {
            if ([oneView isMemberOfClass:[UIToolbar class]]) {
                [[oneView viewWithTag:12345] setHidden:YES];
                break;
            }
        }
    } else
        mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPhone" bundle:nil];
    activeController = mapConfigViewController;
    
    [self.view addSubview:mapConfigViewController.view];
    
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    [mapConfigViewController viewWillAppear:animated];
    [teamConfigViewController viewWillAppear:animated];
    [schemeWeaponConfigViewController viewWillAppear:animated];
    // ADD other controllers here
     
    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [mapConfigViewController viewDidAppear:animated];
    [teamConfigViewController viewDidAppear:animated];
    [schemeWeaponConfigViewController viewDidAppear:animated];
    [super viewDidAppear:animated];
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
    if (mapConfigViewController.view.superview == nil) 
        mapConfigViewController = nil;
    if (teamConfigViewController.view.superview == nil)
        teamConfigViewController = nil;
    if (schemeWeaponConfigViewController.view.superview == nil)
        schemeWeaponConfigViewController = nil;
    activeController = nil;
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    activeController = nil;
    mapConfigViewController = nil;
    teamConfigViewController = nil;
    schemeWeaponConfigViewController = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}

-(void) dealloc {
    [activeController release];
    [mapConfigViewController release];
    [teamConfigViewController release];
    [schemeWeaponConfigViewController release];
    [super dealloc];
}

@end
