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
 * File created on 18/04/2010.
 */


#import "GameConfigViewController.h"
#import "SDL_uikitappdelegate.h"
#import "TeamConfigViewController.h"
#import "SchemeWeaponConfigViewController.h"
#import "HelpPageViewController.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

@implementation GameConfigViewController
@synthesize hedgehogImage, imgContainer, helpPage;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) buttonPressed:(id) sender {    
    // works even if it's not actually a button
    UIButton *theButton = (UIButton *)sender;
    switch (theButton.tag) {
        case 0:
            playSound(@"backSound");
            if ([mapConfigViewController busy]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wait for the Preview",@"")
                                                                message:NSLocalizedString(@"Before returning the preview needs to be generated",@"")
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
            } else
                [[self parentViewController] dismissModalViewControllerAnimated:YES];
            break;
        case 1:
            playSound(@"clickSound");
            theButton.enabled = NO;
            [self startGame:theButton];
            break;
        case 2:
            playSound(@"clickSound");
            if (self.helpPage == nil)
                self.helpPage = [[HelpPageViewController alloc] initWithNibName:@"HelpPageLobbyViewController" bundle:nil];
            self.helpPage.view.alpha = 0;
            [self.view addSubview:helpPage.view];
            [UIView beginAnimations:@"helplobby" context:NULL];
            self.helpPage.view.alpha = 1;
            [UIView commitAnimations];
            break;
        default:
            DLog(@"Nope");
            break;
    }
}

-(IBAction) segmentPressed:(id) sender {
    UISegmentedControl *theSegment = (UISegmentedControl *)sender;

    playSound(@"selSound");
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

-(BOOL) isEverythingSet {
    // don't start playing if the preview is in progress
    if ([mapConfigViewController busy]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wait for the Preview",@"")
                                                        message:NSLocalizedString(@"Before playing the preview needs to be generated",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    
    // play only if there is more than one team
    if ([teamConfigViewController.listOfSelectedTeams count] < 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too few teams playing",@"")
                                                        message:NSLocalizedString(@"Select at least two teams to play a game",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    
    // play if there's room for enough hogs in the selected map
    int hogs = 0;
    for (NSDictionary *teamData in teamConfigViewController.listOfSelectedTeams)
        hogs += [[teamData objectForKey:@"number"] intValue];
    
    if (hogs > mapConfigViewController.maxHogs) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too many hogs",@"")
                                                        message:NSLocalizedString(@"The map is too small for that many hogs",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    
    if ([teamConfigViewController.listOfSelectedTeams count] > 6) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too many teams",@"")
                                                        message:NSLocalizedString(@"Max six teams are allowed in the same game",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    
    if ([schemeWeaponConfigViewController.selectedScheme length] == 0 || [schemeWeaponConfigViewController.selectedWeapon length] == 0 ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing detail",@"")
                                                        message:NSLocalizedString(@"Select one Scheme and one Weapon for this game",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }

    return YES;
}

-(void) startGame:(UIButton *)button {
    button.enabled = YES;

    if ([self isEverythingSet] == NO)
        return;

    // create the configuration file that is going to be sent to engine
    NSDictionary *gameDictionary = [NSDictionary dictionaryWithObjectsAndKeys:mapConfigViewController.seedCommand,@"seed_command",
                                                                      mapConfigViewController.templateFilterCommand,@"templatefilter_command",
                                                                      mapConfigViewController.mapGenCommand,@"mapgen_command",
                                                                      mapConfigViewController.mazeSizeCommand,@"mazesize_command",
                                                                      mapConfigViewController.themeCommand,@"theme_command",
                                                                      mapConfigViewController.staticMapCommand,@"staticmap_command",
                                                                      mapConfigViewController.missionCommand,@"mission_command",  
                                                                      teamConfigViewController.listOfSelectedTeams,@"teams_list",
                                                                      schemeWeaponConfigViewController.selectedScheme,@"scheme",
                                                                      schemeWeaponConfigViewController.selectedWeapon,@"weapon",
                                                                      nil];

    // finally launch game and remove this controller
    DLog(@"sending config %@", gameDictionary);

    if ([[gameDictionary allKeys] count] == 10) {
        NSDictionary *allDataNecessary = [NSDictionary dictionaryWithObjectsAndKeys:gameDictionary,@"game_dictionary", @"",@"savefile",
                                                                                    [NSNumber numberWithBool:NO],@"netgame", nil];
        [[SDLUIKitDelegate sharedAppDelegate] startSDLgame:allDataNecessary];
        
        // tell controllers that they're being reloaded
        [mapConfigViewController viewWillAppear:YES];
    } else {
        DLog(@"gameconfig data not complete!!\nmapConfigViewController = %@\nteamConfigViewController = %@\nschemeWeaponConfigViewController = %@\n",
             mapConfigViewController, teamConfigViewController, schemeWeaponConfigViewController);
        [self.parentViewController dismissModalViewControllerAnimated:YES];

        // present an alert to the user, with an image on the ipad (too big for the iphone)
        NSString *msg = NSLocalizedString(@"Something went wrong with your configuration. Please try again.",@"");
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            msg = [msg stringByAppendingString:@"\n\n\n\n\n\n\n\n"];    // this makes space for the image

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops"
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UIImageView *deniedImg = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"denied.png"]];
            deniedImg.frame = CGRectMake(25, 80, 240, 160);
            [alert addSubview:deniedImg];
            [deniedImg release];
        }
        [alert show];
        [alert release];
    }

}

-(void) viewDidLoad {
    self.view.backgroundColor = [UIColor blackColor];

    CGRect screen = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(0, 0, screen.size.height, screen.size.width);

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // load a base image that will be updated in viewWill Load
        NSString *filePath = [NSString stringWithFormat:@"%@/Hedgehog.png",GRAPHICS_DIRECTORY()];
        UIImage *sprite = [[UIImage alloc] initWithContentsOfFile:filePath andCutAt:CGRectMake(96, 0, 32, 32)];
        self.hedgehogImage = sprite;
        [sprite release];
        srandom(time(NULL));
        
        // load other controllers
        if (mapConfigViewController == nil)
            mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPad" bundle:nil];
        mapConfigViewController.delegate = self;
        if (teamConfigViewController == nil)
            teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        teamConfigViewController.view.frame = CGRectMake(362, 200, 300, 480);
        teamConfigViewController.view.backgroundColor = [UIColor clearColor];
        [mapConfigViewController.view addSubview:teamConfigViewController.view];
        if (schemeWeaponConfigViewController == nil)
            schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        schemeWeaponConfigViewController.view.frame = CGRectMake(10, 70, 300, 550);
        [mapConfigViewController.view addSubview:schemeWeaponConfigViewController.view];
        mapConfigViewController.view.frame = CGRectMake(0, 0, screen.size.height, screen.size.width);
    } else {
        // this is the visible controller
        mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPhone" bundle:nil];
        // this must be loaded & added to auto set default scheme and ammo
        schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.view addSubview:schemeWeaponConfigViewController.view];
    }
    activeController = mapConfigViewController;

    [self.view addSubview:mapConfigViewController.view];

    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        NSArray *hatArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:HATS_DIRECTORY() error:NULL];
        int numberOfHats = [hatArray count];
        if (self.imgContainer == nil)
            self.imgContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
        
        for (int i=0; i < 1 + random()%40; i++) {
            NSString *hat = [hatArray objectAtIndex:random()%numberOfHats];
            
            NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@", HATS_DIRECTORY(), hat];
            UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile: hatFile andCutAt:CGRectMake(0, 0, 32, 32)];
            [hatFile release];
            UIImage *hogWithHat = [self.hedgehogImage mergeWith:hatSprite atPoint:CGPointMake(0, -5)];
            [hatSprite release];
            
            UIImageView *hog = [[UIImageView alloc] initWithImage:hogWithHat];
            hog.frame = CGRectMake(10*(i+1)+random()%30, 30, 32, 32);
            [self.imgContainer addSubview:hog];
            [hog release];
        }
        [self.view addSubview:self.imgContainer];
    }

    [mapConfigViewController viewWillAppear:animated];
    [teamConfigViewController viewWillAppear:animated];
    [schemeWeaponConfigViewController viewWillAppear:animated];
    // add other controllers here and below

    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [mapConfigViewController viewDidAppear:animated];
    [teamConfigViewController viewDidAppear:animated];
    [schemeWeaponConfigViewController viewDidAppear:animated];
    [super viewDidAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [mapConfigViewController viewWillDisappear:animated];
    [teamConfigViewController viewWillDisappear:animated];
    [schemeWeaponConfigViewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.imgContainer removeFromSuperview];
        releaseAndNil(self.imgContainer);
    }
    
    [mapConfigViewController viewDidDisappear:animated];
    [teamConfigViewController viewDidDisappear:animated];
    [schemeWeaponConfigViewController viewDidDisappear:animated];
    [super viewDidDisappear:animated];
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    if (activeController.view.superview == nil)
        activeController = nil;
    if (mapConfigViewController.view.superview == nil)
        mapConfigViewController = nil;
    if (teamConfigViewController.view.superview == nil)
        teamConfigViewController = nil;
    if (schemeWeaponConfigViewController.view.superview == nil)
        schemeWeaponConfigViewController = nil;    
    // Release any cached data, images, etc that aren't in use.

    self.imgContainer = nil;
    [super didReceiveMemoryWarning];
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    hedgehogImage = nil;
    imgContainer = nil;
    activeController = nil;
    mapConfigViewController = nil;
    teamConfigViewController = nil;
    schemeWeaponConfigViewController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [hedgehogImage release];
    [imgContainer release];
    [mapConfigViewController release];
    [teamConfigViewController release];
    [schemeWeaponConfigViewController release];
    [super dealloc];
}

@end
