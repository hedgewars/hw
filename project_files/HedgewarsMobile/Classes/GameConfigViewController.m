/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import "GameConfigViewController.h"
#import "MapConfigViewController.h"
#import "TeamConfigViewController.h"
#import "SchemeWeaponConfigViewController.h"
#import "GameInterfaceBridge.h"
#import "HelpPageLobbyViewController.h"

@interface GameConfigViewController ()
@property (nonatomic, retain) IBOutlet UISegmentedControl *tabsSegmentedControl; //iPhone only

@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton; //iPhone only
@property (nonatomic, retain) IBOutlet UIBarButtonItem *startButton; //iPhone only
@end

@implementation GameConfigViewController
@synthesize imgContainer, titleImage, sliderBackground, helpPage,
            mapConfigViewController, teamConfigViewController, schemeWeaponConfigViewController;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark - Buttons

-(IBAction) buttonPressed:(id) sender {
    UIButton *theButton = (UIButton *)sender;

    switch (theButton.tag) {
        case 0:
            if ([self.mapConfigViewController busy]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wait for the Preview",@"")
                                                                message:NSLocalizedString(@"Before returning the preview needs to be generated",@"")
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok, got it",@"")
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
            } else {
                [[AudioManagerController mainManager] playBackSound];
                [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        case 1:
            [[AudioManagerController mainManager] playClickSound];
            if ([self isEverythingSet] == NO)
                return;
            theButton.enabled = NO;
            [self clearImgContainer];
            [self startGame:theButton];

            break;
        case 2:
            [[AudioManagerController mainManager] playClickSound];
            if (self.helpPage == nil)
                self.helpPage = [[HelpPageLobbyViewController alloc] initWithNibName:@"HelpPageLobbyViewController-iPad" bundle:nil];
            self.helpPage.view.alpha = 0;
            self.helpPage.view.frame = self.view.frame;
            [self.view addSubview:self.helpPage.view];
            [UIView animateWithDuration:0.5 animations:^{
                self.helpPage.view.alpha = 1;
            }];
            break;
        default:
            DLog(@"Nope");
            break;
    }
}

#pragma mark - Tabs Segmented Control

- (void)localizeTabsSegmentedControl
{
    for (NSUInteger i = 0; i < self.tabsSegmentedControl.numberOfSegments; i++)
    {
        NSString *oldTitle = [self.tabsSegmentedControl titleForSegmentAtIndex:i];
        [self.tabsSegmentedControl setTitle:NSLocalizedString(oldTitle, nil) forSegmentAtIndex:i];
    }
}

-(IBAction) segmentPressed:(id) sender {

    UISegmentedControl *theSegment = (UISegmentedControl *)sender;

    [[AudioManagerController mainManager] playSelectSound];
    switch (theSegment.selectedSegmentIndex) {
        case 0:
            // this message is compulsory otherwise the table won't be loaded at all
            [self.mapConfigViewController viewWillAppear:NO];
            [self.view bringSubviewToFront:self.mapConfigViewController.view];
            break;
        case 1:
            // this message is compulsory otherwise the table won't be loaded at all
            [self.teamConfigViewController viewWillAppear:NO];
            [self.view bringSubviewToFront:self.teamConfigViewController.view];
            break;
        case 2:
            // this message is compulsory otherwise the table won't be loaded at all
            [schemeWeaponConfigViewController viewWillAppear:NO];
            [self.view bringSubviewToFront:schemeWeaponConfigViewController.view];
            break;
        case 3:
            if (helpPage == nil) {
                helpPage = [[HelpPageLobbyViewController alloc] initWithNibName:@"HelpPageLobbyViewController-iPhone" bundle:nil];
                CGRect helpPageFrame = self.view.frame;
                helpPageFrame.size.height -= 44; //toolbar height
                self.helpPage.view.frame = helpPageFrame;
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

#pragma mark -

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
    if ((int)[self.teamConfigViewController.listOfSelectedTeams count] > HW_getMaxNumberOfTeams()) {
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

    NSString *script = self.mapConfigViewController.missionCommand;
    if ([script isEqualToString:@""])
        script = self.schemeWeaponConfigViewController.scriptCommand;

    // create the configuration file that is going to be sent to engine
    NSDictionary *gameDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    self.mapConfigViewController.seedCommand,@"seed_command",
                                    self.mapConfigViewController.templateFilterCommand,@"templatefilter_command",
                                    self.mapConfigViewController.mapGenCommand,@"mapgen_command",
                                    self.mapConfigViewController.mazeSizeCommand,@"mazesize_command",
                                    self.mapConfigViewController.themeCommand,@"theme_command",
                                    self.mapConfigViewController.staticMapCommand,@"staticmap_command",
                                    self.teamConfigViewController.listOfSelectedTeams,@"teams_list",
                                    self.schemeWeaponConfigViewController.selectedScheme,@"scheme",
                                    self.schemeWeaponConfigViewController.selectedWeapon,@"weapon",
                                    script,@"mission_command",
                                    nil];

    [GameInterfaceBridge registerCallingController:self];
    [GameInterfaceBridge startLocalGame:gameDictionary];
    [gameDictionary release];
}

-(void) loadNiceHogs
{
    @autoreleasepool
    {
    
        NSString *filePath = [[NSString alloc] initWithFormat:@"%@/Hedgehog/Idle.png",GRAPHICS_DIRECTORY()];
        UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:filePath];
        [filePath release];

        NSArray *hatArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:HATS_DIRECTORY() error:NULL];
        NSUInteger numberOfHats = [hatArray count];
        int animationFrames = IS_VERY_POWERFUL([HWUtils modelType]) ? 16 : 1;
        
        self.imgContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
        NSInteger numberOfHogs = 1 + arc4random_uniform(15);
        DLog(@"Drawing %ld nice hedgehogs", (long)numberOfHogs);
        for (int i = 0; i < numberOfHogs; i++) {
            NSString *hat = [hatArray objectAtIndex:arc4random_uniform((int)numberOfHats)];

            NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@", HATS_DIRECTORY(), hat];
            UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile:hatFile];
            NSMutableArray *animation = [[NSMutableArray alloc] initWithCapacity:animationFrames];
            for (int j = 0; j < animationFrames; j++) {
                int x = ((j*32)/(int)hatSprite.size.height)*32;
                int y = (j*32)%(int)hatSprite.size.height;
                UIImage *hatSpriteFrame = [hatSprite cutAt:CGRectMake(x, y, 32, 32)];
                UIImage *hogSpriteFrame = [hogSprite cutAt:CGRectMake(x, y, 32, 32)];
                UIImage *hogWithHat = [hogSpriteFrame mergeWith:hatSpriteFrame atPoint:CGPointMake(0, 5)];
                if (hogWithHat) {
                    [animation addObject:hogWithHat];
                }
            }
            [hatSprite release];
            [hatFile release];

            UIImageView *hog = [[UIImageView alloc] initWithImage:[animation firstObject]];
            hog.animationImages = animation;
            hog.animationDuration = 3;
            [animation release];

            int x = 20*i+arc4random_uniform(128);
            while (x > 320 - 32)
                x = i*arc4random_uniform(32);
            
            hog.frame = CGRectMake(x, 25, hog.frame.size.width, hog.frame.size.height);
            [self.imgContainer addSubview:hog];
            [hog startAnimating];
            [hog release];
        }
        [hogSprite release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.view addSubview:self.imgContainer];
            
            // don't place the nice hogs if there is no space for them
            if ((self.interfaceOrientation == UIInterfaceOrientationPortrait ||
                 self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown))
                self.imgContainer.alpha = 0;
            
            self.isDrawingNiceHogs = NO;
        });
    }
}

- (void)clearImgContainer
{
    for (UIView *oneView in [self.imgContainer subviews])
    {
        if ([oneView isMemberOfClass:[UIImageView class]])
        {
            UIImageView *anImageView = (UIImageView *)oneView;
            [anImageView removeFromSuperview];
        }
    }
    
    [self.imgContainer removeFromSuperview];
    self.imgContainer = nil;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];

    CGRect screenRect = [[UIScreen mainScreen] safeBounds];
    self.view.frame = screenRect;

    if (IS_IPAD())
    {
        // the label for the filter slider
        UILabel *backLabel = [[UILabel alloc] initWithFrame:CGRectMake(116, 714, 310, 40)
                                                   andTitle:nil
                                            withBorderWidth:2.0f];
        self.sliderBackground = backLabel;
        [backLabel release];
        [self.view addSubview:self.sliderBackground];

        // the label for max hogs
        UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(598, 714, 310, 40)
                                                  andTitle:NSLocalizedString(@"Loading...",@"")
                                           withBorderWidth:2.0f];
        maxLabel.font = [UIFont italicSystemFontOfSize:[UIFont labelFontSize]];
        maxLabel.textColor = [UIColor whiteColor];
        maxLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:maxLabel];
        self.mapConfigViewController.maxLabel = maxLabel;
        [maxLabel release];
    }
    else
    {
        [self localizeTabsSegmentedControl];
        
        [self.backButton setTitle:NSLocalizedString(@"Back", nil)];
        [self.startButton setTitle:NSLocalizedString(@"Start", nil)];
        
        self.mapConfigViewController.view.frame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height-44);
    }
    
    [self.view addSubview:self.mapConfigViewController.view];
    [self.view bringSubviewToFront:self.mapConfigViewController.slider];
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval) duration {
    if (IS_IPAD() == NO)
        return;

    [self updateiPadUIForInterfaceOrientation:toInterfaceOrientation];

    if (self.helpPage)
    {
        self.helpPage.view.frame = self.view.frame;
    }
}

- (void)updateiPadUIForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
         interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        self.imgContainer.alpha = 1;
        self.titleImage.frame = CGRectMake(357, 17, 309, 165);
        self.schemeWeaponConfigViewController.view.frame = CGRectMake(0, 60, 320, 620);
        self.mapConfigViewController.view.frame = CGRectMake(704, 0, 320, 680);
        self.teamConfigViewController.view.frame = CGRectMake(337, 187, 350, 505);
        self.mapConfigViewController.maxLabel.frame = CGRectMake(121, 714, 300, 40);
        self.sliderBackground.frame = CGRectMake(603, 714, 300, 40);
        self.mapConfigViewController.slider.frame = CGRectMake(653, 724, 200, 23);
    } else {
        self.imgContainer.alpha = 0;
        self.titleImage.frame = CGRectMake(37, 28, 309, 165);
        self.schemeWeaponConfigViewController.view.frame = CGRectMake(0, 214, 378, 366);
        self.mapConfigViewController.view.frame = CGRectMake(390, 0, 378, 580);
        self.teamConfigViewController.view.frame = CGRectMake(170, 590, 428, 366);
        self.mapConfigViewController.maxLabel.frame = CGRectMake(104, 975, 200, 40);
        self.sliderBackground.frame = CGRectMake(465, 975, 200, 40);
        self.mapConfigViewController.slider.frame = CGRectMake(475, 983, 180, 23);
    }
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (IS_IPAD() && !self.imgContainer && !self.isDrawingNiceHogs)
    {
        self.isDrawingNiceHogs = YES;
        [NSThread detachNewThreadSelector:@selector(loadNiceHogs) toTarget:self withObject:nil];
    }
    
    if (IS_IPAD())
    {
        // we assume here what 'statusBarOrientation' will never be changed manually!
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self updateiPadUIForInterfaceOrientation:currentOrientation];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (IS_IPAD())
    {
        // need to call this again in order to fix layout on iOS 9 when going back from rotated stats page
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self updateiPadUIForInterfaceOrientation:currentOrientation];
    }
}

-(void) didReceiveMemoryWarning
{
    [self clearImgContainer];

    if (self.titleImage.superview == nil)
        self.titleImage = nil;
    if (self.sliderBackground.superview == nil)
        self.sliderBackground = nil;

    if (self.mapConfigViewController.view.superview == nil)
        self.mapConfigViewController = nil;
    if (self.teamConfigViewController.view.superview == nil)
        self.teamConfigViewController = nil;
    if (self.schemeWeaponConfigViewController.view.superview == nil)
        self.schemeWeaponConfigViewController = nil;
    if (self.helpPage.view.superview == nil)
        self.helpPage = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.imgContainer = nil;
    self.titleImage = nil;
    self.sliderBackground = nil;
    self.schemeWeaponConfigViewController = nil;
    self.teamConfigViewController = nil;
    self.mapConfigViewController = nil;
    self.helpPage = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(_tabsSegmentedControl);
    releaseAndNil(_backButton);
    releaseAndNil(_startButton);
    releaseAndNil(imgContainer);
    releaseAndNil(titleImage);
    releaseAndNil(sliderBackground);
    releaseAndNil(schemeWeaponConfigViewController);
    releaseAndNil(teamConfigViewController);
    releaseAndNil(mapConfigViewController);
    releaseAndNil(helpPage);
    [super dealloc];
}

@end
