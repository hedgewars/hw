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

@implementation GameConfigViewController
@synthesize availableTeamsTableView, backButton, weaponsButton, schemesButton, mapButton, randomButton, startButton;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}


-(IBAction) buttonPressed:(id) sender {
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
- (void)viewDidLoad {
    self.view.frame = CGRectMake(0, 0, 1024, 1024);
    [super viewDidLoad];
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


-(void) viewDidUnload {
    self.availableTeamsTableView = nil;
    self.backButton = nil;
    self.weaponsButton = nil;
    self.schemesButton = nil;
    self.mapButton = nil;
    self.randomButton = nil;
    self.startButton = nil;
    [super viewDidUnload];
}


-(void) dealloc {
    [availableTeamsTableView release];
    [backButton release];
    [weaponsButton release];
    [schemesButton release];
    [mapButton release];
    [randomButton release];
    [startButton release];
    [super dealloc];
}


@end
