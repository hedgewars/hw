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
#import "MapConfigViewController.h"
#import "TeamConfigViewController.h"
#import "SchemeWeaponConfigViewController.h"
#import "HelpPageViewController.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"
#import "PascalImports.h"

@implementation GameConfigViewController
@synthesize imgContainer, helpPage, mapConfigViewController, teamConfigViewController, schemeWeaponConfigViewController;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) buttonPressed:(id) sender {
    // works even if it's not actually a button
    UIButton *theButton;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        theButton = [[(NSNotification *)sender userInfo] objectForKey:@"sender"];
    else
        theButton = (UIButton *)sender;

    switch (theButton.tag) {
        case 0:
            playSound(@"backSound");
            if ([self.mapConfigViewController busy]) {
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
                [self.view addSubview:mapConfigViewController.view];
            }
            // this message is compulsory otherwise the table won't be loaded at all
            [mapConfigViewController viewWillAppear:NO];
            [self.view bringSubviewToFront:mapConfigViewController.view];
            break;
        case 1:
            if (teamConfigViewController == nil) {
                teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.view addSubview:teamConfigViewController.view];
            }
            // this message is compulsory otherwise the table won't be loaded at all
            [teamConfigViewController viewWillAppear:NO];
            [self.view bringSubviewToFront:teamConfigViewController.view];
            break;
        case 2:
            if (schemeWeaponConfigViewController == nil) {
                schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.view addSubview:schemeWeaponConfigViewController.view];
            }
            // this message is compulsory otherwise the table won't be loaded at all
            [schemeWeaponConfigViewController viewWillAppear:NO];
            [self.view bringSubviewToFront:schemeWeaponConfigViewController.view];
            break;
        default:
            DLog(@"Nope");
            break;
    }
}

-(BOOL) isEverythingSet {
    // don't start playing if the preview is in progress
    if ([self.mapConfigViewController busy]) {
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
    if ([self.teamConfigViewController.listOfSelectedTeams count] < 2) {
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
    
    if (hogs > self.mapConfigViewController.maxHogs) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too many hogs",@"")
                                                        message:NSLocalizedString(@"The map is too small for that many hogs",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    
    if ([self.teamConfigViewController.listOfSelectedTeams count] > HW_getMaxNumberOfTeams()) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too many teams",@"")
                                                        message:NSLocalizedString(@"Max six teams are allowed in the same game",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    
    if ([self.schemeWeaponConfigViewController.selectedScheme length] == 0 || [self.schemeWeaponConfigViewController.selectedWeapon length] == 0 ) {
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
    NSDictionary *gameDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self.mapConfigViewController.seedCommand,@"seed_command",
                                    self.mapConfigViewController.templateFilterCommand,@"templatefilter_command",
                                    self.mapConfigViewController.mapGenCommand,@"mapgen_command",
                                    self.mapConfigViewController.mazeSizeCommand,@"mazesize_command",
                                    self.mapConfigViewController.themeCommand,@"theme_command",
                                    self.mapConfigViewController.staticMapCommand,@"staticmap_command",
                                    self.mapConfigViewController.missionCommand,@"mission_command",  
                                    self.teamConfigViewController.listOfSelectedTeams,@"teams_list",
                                    self.schemeWeaponConfigViewController.selectedScheme,@"scheme",
                                    self.schemeWeaponConfigViewController.selectedWeapon,@"weapon",
                                    [NSNumber numberWithInt:self.interfaceOrientation],@"orientation",
                                    nil];
    
    // finally launch game and remove this controller
    DLog(@"sending config %@", gameDictionary);

    if ([[gameDictionary allKeys] count] == 11) {
        NSDictionary *allDataNecessary = [NSDictionary dictionaryWithObjectsAndKeys:gameDictionary,@"game_dictionary", @"",@"savefile",
                                                                                    [NSNumber numberWithBool:NO],@"netgame", nil];
        [[SDLUIKitDelegate sharedAppDelegate] startSDLgame:allDataNecessary];
        
        // tell controllers that they're being reloaded
        [self.mapConfigViewController viewWillAppear:YES];
        [self.schemeWeaponConfigViewController viewWillAppear:YES];
    } else {
        DLog(@"gameconfig data not complete!!");
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

-(void) loadNiceHogs {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *filePath = [NSString stringWithFormat:@"%@/Hedgehog.png",GRAPHICS_DIRECTORY()];
    UIImage *sprite = [[UIImage alloc] initWithContentsOfFile:filePath andCutAt:CGRectMake(96, 0, 32, 32)];
    
    NSArray *hatArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:HATS_DIRECTORY() error:NULL];
    int numberOfHats = [hatArray count];

    if (self.imgContainer != nil)
        [self.imgContainer removeFromSuperview];
    
    self.imgContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
    for (int i = 0; i < 1 + random()%40; i++) {
        NSString *hat = [hatArray objectAtIndex:random()%numberOfHats];
        
        NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@", HATS_DIRECTORY(), hat];
        UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile: hatFile andCutAt:CGRectMake(0, 0, 32, 32)];
        [hatFile release];
        UIImage *hogWithHat = [sprite mergeWith:hatSprite atPoint:CGPointMake(0, 5)];
        [hatSprite release];
        
        UIImageView *hog = [[UIImageView alloc] initWithImage:hogWithHat];
        hog.frame = CGRectMake(10*(i+1)+random()%30, 30, 32, 32);
        [self.imgContainer addSubview:hog];
        [hog release];
    }
    [self.view addSubview:self.imgContainer];
    [sprite release];
    [pool drain];
}

-(void) viewDidLoad {
    self.view.backgroundColor = [UIColor blackColor];

    CGRect screen = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(0, 0, screen.size.height, screen.size.width);

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(buttonPressed:)
                                                     name:@"buttonPressed"
                                                   object:nil];
        srandom(time(NULL));
        
        // load other controllers
        if (self.mapConfigViewController == nil)
            self.mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPad" bundle:nil];
        if (self.teamConfigViewController == nil)
            self.teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.mapConfigViewController.view addSubview:self.teamConfigViewController.view];
        if (self.schemeWeaponConfigViewController == nil)
            self.schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.mapConfigViewController.view addSubview:schemeWeaponConfigViewController.view];
        self.mapConfigViewController.view.frame = CGRectMake(0, 0, screen.size.height, screen.size.width);
        self.teamConfigViewController.view.frame = CGRectMake(348, 200, 328, 480);
        self.schemeWeaponConfigViewController.view.frame = CGRectMake(10, 70, 300, 600);
        
    } else {
        // this is the visible controller
        if (self.mapConfigViewController == nil)
            self.mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPhone" bundle:nil];
        // this must be loaded & added in order to auto set default scheme and ammo
        self.schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.view addSubview:self.schemeWeaponConfigViewController.view];
    }
    [self.view addSubview:self.mapConfigViewController.view];

    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [NSThread detachNewThreadSelector:@selector(loadNiceHogs) toTarget:self withObject:nil];

    [self.mapConfigViewController viewWillAppear:animated];
    [self.teamConfigViewController viewWillAppear:animated];
    [self.schemeWeaponConfigViewController viewWillAppear:animated];
    // add other controllers here and below

    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    [self.mapConfigViewController viewDidAppear:animated];
    [self.teamConfigViewController viewDidAppear:animated];
    [self.schemeWeaponConfigViewController viewDidAppear:animated];
    [super viewDidAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [self.mapConfigViewController viewWillDisappear:animated];
    [self.teamConfigViewController viewWillDisappear:animated];
    [self.schemeWeaponConfigViewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [self.mapConfigViewController viewDidDisappear:animated];
    [self.teamConfigViewController viewDidDisappear:animated];
    [self.schemeWeaponConfigViewController viewDidDisappear:animated];
    [super viewDidDisappear:animated];
}

-(void) didReceiveMemoryWarning {
    if (self.mapConfigViewController.view.superview == nil)
        self.mapConfigViewController = nil;
    if (self.teamConfigViewController.view.superview == nil)
        self.teamConfigViewController = nil;
    if (self.schemeWeaponConfigViewController.view.superview == nil)
        self.schemeWeaponConfigViewController = nil;
    if (self.helpPage.view.superview == nil)
        self.helpPage = nil;

    // Release any cached data, images, etc that aren't in use.
    self.imgContainer = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.imgContainer = nil;
    self.mapConfigViewController = nil;
    self.teamConfigViewController = nil;
    self.schemeWeaponConfigViewController = nil;
    self.helpPage = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [imgContainer release];
    [mapConfigViewController release];
    [teamConfigViewController release];
    [schemeWeaponConfigViewController release];
    [helpPage release];
    [super dealloc];
}

@end
