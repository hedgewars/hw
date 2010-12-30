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
#import "StatsPageViewController.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"
#import "PascalImports.h"

@implementation GameConfigViewController
@synthesize imgContainer, helpPage, mapConfigViewController, teamConfigViewController, schemeWeaponConfigViewController;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) buttonPressed:(id) sender {
    UIButton *theButton = (UIButton *)sender;

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
                self.helpPage = [[HelpPageViewController alloc] initWithNibName:@"HelpPageLobbyViewController-iPad" bundle:nil];
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
        case 3:
            if (helpPage == nil) {
                helpPage = [[HelpPageViewController alloc] initWithNibName:@"HelpPageLobbyViewController-iPhone" bundle:nil];
                [self.view addSubview:helpPage.view];
            }
            // this message is compulsory otherwise the table won't be loaded at all
            [helpPage viewWillAppear:NO];
            [self.view bringSubviewToFront:helpPage.view];
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

    // play if there aren't too many teams
    if ([self.teamConfigViewController.listOfSelectedTeams count] > HW_getMaxNumberOfTeams()) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too many teams",@"")
                                                        message:NSLocalizedString(@"You exceeded the maximum number of tems allowed in a game",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }

    // play only if one scheme and one weapon are selected
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

    // play if the gameflags are set correctly (divideteam works only with 2 teams)
    NSString *schemePath = [[NSString alloc] initWithFormat:@"%@/%@",SCHEMES_DIRECTORY(),self.schemeWeaponConfigViewController.selectedScheme];
    NSArray *gameFlags = [[NSDictionary dictionaryWithContentsOfFile:schemePath] objectForKey:@"gamemod"];
    [schemePath release];
    if ([[gameFlags objectAtIndex:2] boolValue] && [self.teamConfigViewController.listOfSelectedTeams count] != 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Scheme mismatch",@"")
                                                        message:NSLocalizedString(@"The scheme you selected allows only for two teams",@"")
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

    NSDictionary *allDataNecessary = [NSDictionary dictionaryWithObjectsAndKeys:
                                      gameDictionary,@"game_dictionary",
                                      [NSNumber numberWithBool:NO],@"netgame",
                                      @"",@"savefile",
                                      nil];
    if (IS_IPAD())
        [[SDLUIKitDelegate sharedAppDelegate] startSDLgame:allDataNecessary];
    else {
        // this causes a sporadic crash on the ipad but without this rotation doesn't work on iphone
        StatsPageViewController *statsPage = [[StatsPageViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self presentModalViewController:statsPage animated:NO];

        statsPage.statsDictionary = [[SDLUIKitDelegate sharedAppDelegate] startSDLgame:allDataNecessary];
        if (statsPage.statsDictionary == nil)
            [statsPage dismissModalViewControllerAnimated:NO];
        else
            [statsPage.tableView reloadData];
        DLog(@"%@",statsPage.statsDictionary);
        [statsPage release];
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
    for (int i = 0; i < 1 + random()%20; i++) {
        NSString *hat = [hatArray objectAtIndex:random()%numberOfHats];
        
        NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@", HATS_DIRECTORY(), hat];
        UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile: hatFile andCutAt:CGRectMake(0, 0, 32, 32)];
        [hatFile release];
        UIImage *hogWithHat = [sprite mergeWith:hatSprite atPoint:CGPointMake(0, 5)];
        [hatSprite release];
        
        UIImageView *hog = [[UIImageView alloc] initWithImage:hogWithHat];
        int x = 15*(i+1)+random()%40;
        if (x + 32 > 300)
            x = i*10;
        hog.frame = CGRectMake(x, 30, 32, 32);
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

    if (IS_IPAD()) {
        // load other controllers
        if (self.mapConfigViewController == nil)
            self.mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPad" bundle:nil];

        UILabel *leftBackground = createLabelWithParams(nil, CGRectMake(0, 60, 320, 620), 2.7f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_ALPHABLUE);
        [self.mapConfigViewController.view addSubview:leftBackground];
        [leftBackground release];
        UILabel *middleBackground = createLabelWithParams(nil, CGRectMake(337, 187, 350, 505), 2.7f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_ALPHABLUE);
        [self.mapConfigViewController.view addSubview:middleBackground];
        [middleBackground release];
        UILabel *rightBackground = createLabelWithParams(nil, CGRectMake(704, 214, 320, 464), 2.7f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_ALPHABLUE);
        [self.mapConfigViewController.view addSubview:rightBackground];
        [rightBackground release];
        UILabel *topBackground = createLabelWithParams(nil, CGRectMake(714, 14, 300, 190), 2.3f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_ALPHABLUE);
        [self.mapConfigViewController.view addSubview:topBackground];
        [topBackground release];
        UILabel *bottomLeftBackground = createLabelWithParams(nil, CGRectMake(106, 714, 320, 40), 2.0f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_ALPHABLUE);
        [self.mapConfigViewController.view addSubview:bottomLeftBackground];
        [bottomLeftBackground release];
        UILabel *bottomRightBackground = createLabelWithParams(NSLocalizedString(@"Max Hogs:                 ",@""), CGRectMake(594, 714, 320, 40), 2.0f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_ALPHABLUE);
        bottomRightBackground.font = [UIFont italicSystemFontOfSize:[UIFont labelFontSize]];
        [self.mapConfigViewController.view addSubview:bottomRightBackground];
        [bottomRightBackground release];
        [self.mapConfigViewController.view bringSubviewToFront:self.mapConfigViewController.maxLabel];
        [self.mapConfigViewController.view bringSubviewToFront:self.mapConfigViewController.sizeLabel];
        [self.mapConfigViewController.view bringSubviewToFront:self.mapConfigViewController.segmentedControl];
        [self.mapConfigViewController.view bringSubviewToFront:self.mapConfigViewController.previewButton];
        [self.mapConfigViewController.view bringSubviewToFront:self.mapConfigViewController.slider];
        [self.mapConfigViewController.view bringSubviewToFront:self.mapConfigViewController.tableView];

        if (self.teamConfigViewController == nil)
            self.teamConfigViewController = [[TeamConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.mapConfigViewController.view addSubview:self.teamConfigViewController.view];
        if (self.schemeWeaponConfigViewController == nil)
            self.schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.mapConfigViewController.view addSubview:schemeWeaponConfigViewController.view];
        self.mapConfigViewController.view.frame = CGRectMake(0, 0, screen.size.height, screen.size.width);
        self.teamConfigViewController.view.frame = CGRectMake(348, 200, 328, 480);
        self.schemeWeaponConfigViewController.view.frame = CGRectMake(10, 70, 300, 600);

        self.mapConfigViewController.parentController = self;
    } else {
        // this is the visible controller
        if (self.mapConfigViewController == nil)
            self.mapConfigViewController = [[MapConfigViewController alloc] initWithNibName:@"MapConfigViewController-iPhone" bundle:nil];
        // this must be loaded & added in order to auto set default scheme and ammo
        self.schemeWeaponConfigViewController = [[SchemeWeaponConfigViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.view addSubview:self.schemeWeaponConfigViewController.view];
    }
    [self.view addSubview:self.mapConfigViewController.view];
    self.mapConfigViewController.externalController = schemeWeaponConfigViewController;

    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    if (IS_IPAD())
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
    if (self.teamConfigViewController.view.superview == nil)
        self.teamConfigViewController = nil;
    if (self.schemeWeaponConfigViewController.view.superview == nil)
        self.schemeWeaponConfigViewController = nil;
    if (self.helpPage.view.superview == nil)
        self.helpPage = nil;
    if (self.mapConfigViewController.view.superview == nil)
        self.mapConfigViewController = nil;

    self.imgContainer = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
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
