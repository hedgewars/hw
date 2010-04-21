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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
            break;
        case 1:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
            [self performSelector:@selector(startSDLgame)
                       withObject:nil
                       afterDelay:0.4];
            break;
    }
}

-(void) startSDLgame {
    [[SDLUIKitDelegate sharedAppDelegate] startSDLgame];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void) viewDidLoad {
    teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
    activeController = teamConfigViewController;
    
    [self.view insertSubview:teamConfigViewController.view atIndex:0];
    
    [super viewDidLoad];
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


-(void) viewDidUnload {
    activeController = nil;
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
    [teamConfigViewController release];
    [availableTeamsTableView release];
    [weaponsButton release];
    [schemesButton release];
    [mapButton release];
    [randomButton release];
    [startButton release];
    [super dealloc];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [activeController viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [activeController viewWillDisappear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidLoad];
    [activeController viewDidAppear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidUnload];
    [activeController viewDidDisappear:animated];
}

@end
