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

@implementation GameConfigViewController
@synthesize availableTeamsTableView, weaponsButton, schemesButton, mapButton, randomButton, startButton;


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
            [self performSelector:@selector(startGame)
                       withObject:nil
                       afterDelay:0.25];
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
                [mapConfigViewController viewWillAppear:NO];  
            }
            activeController = mapConfigViewController;
            break;
        case 1:
            if (teamConfigViewController == nil) {
                teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
                // this message is compulsory otherwise the team table won't be loaded at all
                [teamConfigViewController viewWillAppear:NO];  
            }
            activeController = teamConfigViewController;
            break;
        case 2:
            
            break;
    }
    
    [self.view addSubview:activeController.view];
}

-(void) startGame {
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
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:mapConfigViewController.seedCommand,@"seed_command",
                                                                      mapConfigViewController.templateFilterCommand,@"templatefilter_command",
                                                                      mapConfigViewController.mapGenCommand,@"mapgen_command",
                                                                      mapConfigViewController.mazeSizeCommand,@"mazesize_command",
                                                                      mapConfigViewController.themeCommand,@"theme_command",
                                                                      teamConfigViewController.listOfSelectedTeams,@"teams_list",nil];
    [dict writeToFile:GAMECONFIG_FILE() atomically:YES];
    [dict release];
    [[self parentViewController] dismissModalViewControllerAnimated:YES];
    [[SDLUIKitDelegate sharedAppDelegate] startSDLgame];
}

-(void) viewDidLoad {
    mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPhone" bundle:nil];
    activeController = mapConfigViewController;
    
    [self.view addSubview:mapConfigViewController.view];
    
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    [mapConfigViewController viewWillAppear:animated];
    [teamConfigViewController viewWillAppear:animated];
    // ADD other controllers here
     
    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [mapConfigViewController viewDidAppear:animated];
    [teamConfigViewController viewDidAppear:animated];
    [super viewDidAppear:animated];
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


-(void) viewDidUnload {
    NSLog(@"unloading");
    activeController = nil;
    mapConfigViewController = nil;
    teamConfigViewController = nil;
    self.availableTeamsTableView = nil;
    self.weaponsButton = nil;
    self.schemesButton = nil;
    self.mapButton = nil;
    self.randomButton = nil;
    self.startButton = nil;
    [super viewDidUnload];
}


-(void) dealloc {
    [activeController release];
    [mapConfigViewController release];
    [teamConfigViewController release];
    [availableTeamsTableView release];
    [weaponsButton release];
    [schemesButton release];
    [mapButton release];
    [randomButton release];
    [startButton release];
    [super dealloc];
}

@end
