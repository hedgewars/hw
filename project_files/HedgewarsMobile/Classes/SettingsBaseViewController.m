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
@synthesize targetController, controllerNames, lastIndexPath;

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

    if (IS_IPAD())
    {
        // this class gets loaded twice, we tell the difference by looking at targetController
        if (self.targetController != nil)
        {
            UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
            tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            tableView.delegate = self;
            tableView.dataSource = self;
            [tableView reloadData];
            [self.view addSubview:tableView];
            [self tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [tableView release];
            self.navigationItem.leftBarButtonItem = [self doneButton];
        }
    }
    else
    {
        //iPhone part moved to MainMenuViewController
    }

    [super viewDidLoad];
}

- (UIBarButtonItem *)doneButton
{
    return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                         target:self
                                                         action:@selector(dismissSplitView)] autorelease];
}

-(void) dismissSplitView {
    [[AudioManagerController mainManager] playBackSound];
    [[[HedgewarsAppDelegate sharedAppDelegate] mainViewController] dismissViewControllerAnimated:YES completion:nil];
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
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    UIViewController *nextController = nil;

    if (newRow != oldRow)
    {
        [tableView deselectRowAtIndexPath:lastIndexPath animated:YES];
        [targetController.navigationController popToRootViewControllerAnimated:NO];

        switch (newRow)
        {
            case 0:
                nextController = [[GeneralSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];;
                break;
            case 1:
                nextController = [[TeamSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                break;
            case 2:
                nextController = [[WeaponSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                break;
            case 3:
                nextController = [[SchemeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                break;
            case 4:
                nextController = [[SupportViewController alloc] initWithStyle:UITableViewStyleGrouped];
                break;
        }

        self.lastIndexPath = indexPath;
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        nextController.navigationItem.hidesBackButton = YES;
        [nextController viewWillAppear:NO];
        [targetController.navigationController pushViewController:nextController animated:NO];
        [nextController release];
        
        [[AudioManagerController mainManager] playClickSound];
    }
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning
{
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload
{
    self.controllerNames = nil;
    self.lastIndexPath = nil;
    self.targetController = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc
{
    releaseAndNil(targetController);
    releaseAndNil(controllerNames);
    releaseAndNil(lastIndexPath);
    [super dealloc];
}

@end

