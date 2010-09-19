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
 * File created on 27/03/2010.
 */


#import "MasterViewController.h"
#import "CommodityFunctions.h"
#import "GeneralSettingsViewController.h"
#import "TeamSettingsViewController.h"
#import "WeaponSettingsViewController.h"
#import "SchemeSettingsViewController.h"
#import "SupportViewController.h"

@implementation MasterViewController
@synthesize targetController, controllerNames, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    // the list of selectable controllers
    NSArray *array = [[NSArray alloc] initWithObjects:NSLocalizedString(@"General",@""),
                                                      NSLocalizedString(@"Teams",@""),
                                                      NSLocalizedString(@"Weapons",@""),
                                                      NSLocalizedString(@"Schemes",@""),
                                                      NSLocalizedString(@"Support",@""),
                                                      nil];
    self.controllerNames = array;
    [array release];

    // targetControllers tells whether we're on the right or left side of the splitview -- on iphone we only use the right side
    if (targetController == nil && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (nil == generalSettingsViewController)
            generalSettingsViewController = [[GeneralSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        generalSettingsViewController.navigationItem.hidesBackButton = YES;
        [generalSettingsViewController viewWillAppear:YES];
        [self.navigationController pushViewController:generalSettingsViewController animated:NO];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(dismissSplitView)];
    }
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [controllerNames count];
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
            iconStr = [NSString stringWithFormat:@"%@/Molotov.png",GRAPHICS_DIRECTORY()];
            break;
        case 3:
            iconStr = [NSString stringWithFormat:@"%@/Target.png",GRAPHICS_DIRECTORY()];
            break;
        case 4:
            iconStr = [NSString stringWithFormat:@"%@/Seduction.png",GRAPHICS_DIRECTORY()];
            break;
        default:
            //seduction.png for support page
            DLog(@"Nope");
            break;
    }
    
    if (nil == targetController)
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
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
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    UIViewController *nextController = nil;

    if (newRow != oldRow) {
        [self.tableView deselectRowAtIndexPath:lastIndexPath animated:YES];
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
                    supportViewController = [[SupportViewController alloc] initWithNibName:@"SupportViewController" bundle:nil];
                nextController = supportViewController;
                break;
        }

        nextController.title = [controllerNames objectAtIndex:newRow];
        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        if (nil == targetController) {
            nextController.navigationItem.hidesBackButton = NO;
            [self.navigationController pushViewController:nextController animated:YES];
        } else {
            playSound(@"clickSound");
            nextController.navigationItem.hidesBackButton = YES;
            [targetController.navigationController pushViewController:nextController animated:NO];
        }
    }
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
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
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    self.targetController = nil;
    self.controllerNames = nil;
    self.lastIndexPath = nil;
    generalSettingsViewController = nil;
    teamSettingsViewController = nil;
    weaponSettingsViewController = nil;
    schemeSettingsViewController = nil;
    supportViewController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    targetController = nil;
    [controllerNames release];
    [lastIndexPath release];
    [generalSettingsViewController release];
    [teamSettingsViewController release];
    [weaponSettingsViewController release];
    [schemeSettingsViewController release];
    [supportViewController release];
    [super dealloc];
}

-(IBAction) dismissSplitView {
    playSound(@"backSound");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil];
}

@end

