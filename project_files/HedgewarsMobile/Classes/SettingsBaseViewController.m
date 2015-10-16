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


#import "SettingsBaseViewController.h"
#import "GeneralSettingsViewController.h"
#import "TeamSettingsViewController.h"
#import "WeaponSettingsViewController.h"
#import "SchemeSettingsViewController.h"
#import "SupportViewController.h"


@implementation SettingsBaseViewController
@synthesize tabController, targetController, controllerNames, lastIndexPath;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    // the list of available controllers
    NSArray *array = [[NSArray alloc] initWithObjects:NSLocalizedString(@"General",@""),
                                                      NSLocalizedString(@"Teams",@""),
                                                      NSLocalizedString(@"Weapons",@""),
                                                      NSLocalizedString(@"Schemes",@""),
                                                      NSLocalizedString(@"Support",@""),
                                                      nil];
    self.controllerNames = array;
    [array release];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(dismissSplitView)];
    if (IS_IPAD()) {
        // this class gets loaded twice, we tell the difference by looking at targetController
        if (self.targetController != nil) {
            UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
            tableView.delegate = self;
            tableView.dataSource = self;
            [tableView reloadData];
            [self.view addSubview:tableView];
            [self tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [tableView release];
            self.navigationItem.leftBarButtonItem = doneButton;
        }
    } else {
        // this class just loads all controllers and set up tabbar and navigation controllers
        NSMutableArray *tabBarNavigationControllers = [[NSMutableArray alloc] initWithCapacity:5];
        UINavigationController *navController = nil;

        if (nil == generalSettingsViewController) {
            generalSettingsViewController = [[GeneralSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            generalSettingsViewController.tabBarItem = [self tabBarItemWithTitle:[self.controllerNames objectAtIndex:0] imageName:@"flower" selectedImageName:@"flower_filled"];
            navController = [[UINavigationController alloc] initWithRootViewController:generalSettingsViewController];
            generalSettingsViewController.navigationItem.backBarButtonItem = doneButton;
            generalSettingsViewController.navigationItem.leftBarButtonItem = doneButton;
            [generalSettingsViewController release];
            [tabBarNavigationControllers addObject:navController];
            releaseAndNil(navController);
        }
        if (nil == teamSettingsViewController) {
            teamSettingsViewController = [[TeamSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            teamSettingsViewController.tabBarItem = [self tabBarItemWithTitle:[self.controllerNames objectAtIndex:1] imageName:@"teams" selectedImageName:@"teams_filled"];
            navController = [[UINavigationController alloc] initWithRootViewController:teamSettingsViewController];
            teamSettingsViewController.navigationItem.backBarButtonItem = doneButton;
            teamSettingsViewController.navigationItem.leftBarButtonItem = doneButton;
            [tabBarNavigationControllers addObject:navController];
            releaseAndNil(navController);
        }
        if (nil == weaponSettingsViewController) {
            weaponSettingsViewController = [[WeaponSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            weaponSettingsViewController.tabBarItem = [self tabBarItemWithTitle:[self.controllerNames objectAtIndex:2] imageName:@"bullet" selectedImageName:@"bullet_filled"];
            navController = [[UINavigationController alloc] initWithRootViewController:weaponSettingsViewController];
            weaponSettingsViewController.navigationItem.backBarButtonItem = doneButton;
            weaponSettingsViewController.navigationItem.leftBarButtonItem = doneButton;
            [tabBarNavigationControllers addObject:navController];
            releaseAndNil(navController);
        }
        if (nil == schemeSettingsViewController) {
            schemeSettingsViewController = [[SchemeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            schemeSettingsViewController.tabBarItem = [self tabBarItemWithTitle:[self.controllerNames objectAtIndex:3] imageName:@"target" selectedImageName:@"target_filled"];
            navController = [[UINavigationController alloc] initWithRootViewController:schemeSettingsViewController];
            schemeSettingsViewController.navigationItem.backBarButtonItem = doneButton;
            schemeSettingsViewController.navigationItem.leftBarButtonItem = doneButton;
            [tabBarNavigationControllers addObject:navController];
            releaseAndNil(navController);
        }
        if (nil == supportViewController) {
            supportViewController = [[SupportViewController alloc] initWithStyle:UITableViewStyleGrouped];
            supportViewController.tabBarItem = [self tabBarItemWithTitle:[self.controllerNames objectAtIndex:4] imageName:@"heart" selectedImageName:@"heart_filled"];
            navController = [[UINavigationController alloc] initWithRootViewController:supportViewController];
            supportViewController.navigationItem.backBarButtonItem = doneButton;
            supportViewController.navigationItem.leftBarButtonItem = doneButton;
            [tabBarNavigationControllers addObject:navController];
            releaseAndNil(navController);
        }

        self.tabController = [[UITabBarController alloc] init];
        self.tabController.viewControllers = tabBarNavigationControllers;
        self.tabController.delegate = self;

        [self.view addSubview:self.tabController.view];
    }
    [doneButton release];
    [super viewDidLoad];
}

- (UITabBarItem *)tabBarItemWithTitle: (NSString *)title
                            imageName: (NSString *)imageName
                    selectedImageName: (NSString *)selectedImageName
{
    return [[[UITabBarItem alloc] initWithTitle:title
                                          image:[UIImage imageNamed:imageName]
                                  selectedImage:[UIImage imageNamed:selectedImageName]] autorelease];
}

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [viewController viewWillAppear:NO];
}

-(void) dismissSplitView {
    [[AudioManagerController mainManager] playBackSound];
    [[[HedgewarsAppDelegate sharedAppDelegate] mainViewController] dismissViewControllerAnimated:YES completion:nil];
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (IS_IPAD() == NO)
        return;

    if (self.targetController != nil) {
        CGRect screenRect = [[UIScreen mainScreen] safeBounds];
        self.view.frame = CGRectMake(0, 0, 320, screenRect.size.height);
    }
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.controllerNames count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    NSString *iconStr = nil;
    switch ([indexPath row]) {
        case 0:
            iconStr = [NSString stringWithFormat:@"%@/TargetBee.png",GRAPHICS_DIRECTORY()];
            break;
        case 1:
            iconStr = [NSString stringWithFormat:@"%@/Egg.png",GRAPHICS_DIRECTORY()];
            break;
        case 2:
            iconStr = [NSString stringWithFormat:@"%@/cheese.png",GRAPHICS_DIRECTORY()];
            break;
        case 3:
            iconStr = [NSString stringWithFormat:@"%@/Target.png",GRAPHICS_DIRECTORY()];
            break;
        case 4:
            iconStr = [NSString stringWithFormat:@"%@/Seduction.png",GRAPHICS_DIRECTORY()];
            break;
        default:
            DLog(@"Nope");
            break;
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = [controllerNames objectAtIndex:[indexPath row]];
    UIImage *icon = [[UIImage alloc] initWithContentsOfFile:iconStr];
    cell.imageView.image = icon;
    [icon release];

    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    UIViewController *nextController = nil;

    if (newRow != oldRow) {
        [tableView deselectRowAtIndexPath:lastIndexPath animated:YES];
        [targetController.navigationController popToRootViewControllerAnimated:NO];

        switch (newRow) {
            case 0:
                if (nil == generalSettingsViewController)
                    generalSettingsViewController = [[GeneralSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = generalSettingsViewController;
                break;
            case 1:
                if (nil == teamSettingsViewController)
                    teamSettingsViewController = [[TeamSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = teamSettingsViewController;
                break;
            case 2:
                if (nil == weaponSettingsViewController)
                    weaponSettingsViewController = [[WeaponSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = weaponSettingsViewController;
                break;
            case 3:
                if (nil == schemeSettingsViewController)
                    schemeSettingsViewController = [[SchemeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = schemeSettingsViewController;
                break;
            case 4:
                if (nil == supportViewController)
                    supportViewController = [[SupportViewController alloc] initWithStyle:UITableViewStyleGrouped];
                nextController = supportViewController;
                break;
        }

        self.lastIndexPath = indexPath;
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        nextController.navigationItem.hidesBackButton = YES;
        [nextController viewWillAppear:NO];
        [targetController.navigationController pushViewController:nextController animated:NO];
        [[AudioManagerController mainManager] playClickSound];
    }
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    if (generalSettingsViewController.view.superview == nil)
        generalSettingsViewController = nil;
    if (teamSettingsViewController.view.superview == nil)
        teamSettingsViewController = nil;
    if (weaponSettingsViewController.view.superview == nil)
        weaponSettingsViewController = nil;
    if (schemeSettingsViewController.view.superview == nil)
        schemeSettingsViewController = nil;
    if (supportViewController.view.superview == nil)
        supportViewController = nil;
    if (tabController.view.superview == nil)
        tabController = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.controllerNames = nil;
    self.lastIndexPath = nil;
    self.targetController = nil;
    self.tabController = nil;
    generalSettingsViewController = nil;
    teamSettingsViewController = nil;
    weaponSettingsViewController = nil;
    schemeSettingsViewController = nil;
    supportViewController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(targetController);
    releaseAndNil(controllerNames);
    releaseAndNil(lastIndexPath);
    releaseAndNil(tabController);
    releaseAndNil(generalSettingsViewController);
    releaseAndNil(teamSettingsViewController);
    releaseAndNil(weaponSettingsViewController);
    releaseAndNil(schemeSettingsViewController);
    releaseAndNil(supportViewController);
    [super dealloc];
}


-(void) viewWillDisappear:(BOOL)animated {
    // this will send -viewWillDisappear: only the active view
    [self.tabController viewWillDisappear:animated];
    // let's send that to every page, even though only GeneralSettingsViewController needs it
    [generalSettingsViewController viewWillDisappear:animated];
    [teamSettingsViewController viewWillDisappear:animated];
    [weaponSettingsViewController viewWillDisappear:animated];
    [schemeSettingsViewController viewWillDisappear:animated];
    [supportViewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}

@end

