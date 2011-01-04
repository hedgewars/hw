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
 * File created on 13/06/2010.
 */


#import "SchemeWeaponConfigViewController.h"
#import "CommodityFunctions.h"
#import "SDL_uikitappdelegate.h"

#define LABEL_TAG 57423

@implementation SchemeWeaponConfigViewController
@synthesize listOfSchemes, listOfWeapons, lastIndexPath_sc, lastIndexPath_we, selectedScheme, selectedWeapon, syncSwitch;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.view.frame = CGRectMake(0, 0, screenSize.height, screenSize.width - 44);

    self.selectedScheme = nil;
    self.selectedWeapon = nil;

    if ([self.tableView respondsToSelector:@selector(setBackgroundView:)]) {
        if (IS_IPAD())
            [self.tableView setBackgroundView:nil];
        else {
            UIImage *backgroundImage = [[UIImage alloc] initWithContentsOfFile:@"background~iphone.png"];
            UIImageView *background = [[UIImageView alloc] initWithImage:backgroundImage];
            [backgroundImage release];
            [self.tableView setBackgroundView:background];
            [background release];
        }
    } else {
        self.view.backgroundColor = [UIColor blackColor];
    }

    self.tableView.separatorColor = UICOLOR_HW_YELLOW_BODER;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];

    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:SCHEMES_DIRECTORY() error:NULL];
    self.listOfSchemes = contentsOfDir;

    if (self.selectedScheme == nil && [listOfSchemes containsObject:@"Default.plist"])
        self.selectedScheme = @"Default.plist";
    
    contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:WEAPONS_DIRECTORY() error:NULL];
    self.listOfWeapons = contentsOfDir;
    
    if (self.selectedWeapon == nil && [listOfWeapons containsObject:@"Default.plist"])
        self.selectedWeapon = @"Default.plist";
    
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if (hideSections)
        return 0;
    else
        return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.listOfSchemes count];
    else if (section == 1)
        return [self.listOfWeapons count];
    else
        return 1;
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];

    cell.accessoryView = nil;
    if (0 == section) {
        cell.textLabel.text = [[self.listOfSchemes objectAtIndex:row] stringByDeletingPathExtension];
        NSString *str = [NSString stringWithFormat:@"%@/%@",SCHEMES_DIRECTORY(),[self.listOfSchemes objectAtIndex:row]];
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:str];
        cell.detailTextLabel.text = [dict objectForKey:@"description"];
        [dict release];
        if ([[self.listOfSchemes objectAtIndex:row] isEqualToString:self.selectedScheme]) {
            UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
            cell.accessoryView = checkbox;
            [checkbox release];
            self.lastIndexPath_sc = indexPath;
        }
    } else if (1 == section) {
        cell.textLabel.text = [[self.listOfWeapons objectAtIndex:row] stringByDeletingPathExtension];
        NSString *str = [NSString stringWithFormat:@"%@/%@",WEAPONS_DIRECTORY(),[self.listOfWeapons objectAtIndex:row]];
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:str];
        cell.detailTextLabel.text = [dict objectForKey:@"description"];
        [dict release];
        if ([[self.listOfWeapons objectAtIndex:row] isEqualToString:self.selectedWeapon]) {
            UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
            cell.accessoryView = checkbox;
            [checkbox release];
            self.lastIndexPath_we = indexPath;
        }
    } else {
        if (self.syncSwitch == nil) {
            UISwitch *theSwitch = [[UISwitch alloc] init];
            [theSwitch setOn:YES];
            self.syncSwitch = theSwitch;
            [theSwitch release];
        }
        cell.textLabel.text = IS_IPAD() ? NSLocalizedString(@"Sync Schemes",@"") : NSLocalizedString(@"Sync Schemes and Weapons",@"");
        cell.detailTextLabel.text = IS_IPAD() ? nil : NSLocalizedString(@"Choosing a Scheme will select its associated Weapon",@"");
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.accessoryView = self.syncSwitch;
    }

    cell.backgroundColor = UICOLOR_HW_ALMOSTBLACK;
    cell.textLabel.textColor = UICOLOR_HW_YELLOW_TEXT;
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width * 80/100, 30);
    NSString *text;
    if (section == 0) 
        text = NSLocalizedString(@"Schemes",@"");
    else if (section == 1)
        text = NSLocalizedString(@"Weapons",@"");
    else
        text = NSLocalizedString(@"Options",@"");

    UILabel *theLabel = createBlueLabel(text, frame);
    theLabel.center = CGPointMake(self.view.frame.size.width/2, 20);

    UIView *theView = [[[UIView alloc] init] autorelease];
    [theView addSubview:theLabel];
    [theLabel release];
    return theView;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *lastIndexPath;
    if ([indexPath section] == 0)
        lastIndexPath = self.lastIndexPath_sc;
    else
        lastIndexPath = self.lastIndexPath_we;

    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        //TODO: this code works only for a single section table
        UITableViewCell *newCell = [aTableView cellForRowAtIndexPath:indexPath];
        UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
        newCell.accessoryView = checkbox;
        [checkbox release];
        UITableViewCell *oldCell = [aTableView cellForRowAtIndexPath:lastIndexPath];
        oldCell.accessoryView = nil;

        if ([indexPath section] == 0) {
            self.lastIndexPath_sc = indexPath;
            self.selectedScheme = [self.listOfSchemes objectAtIndex:newRow];
            if (self.syncSwitch.on) {
                for (NSString *str in self.listOfWeapons) {
                    if ([str isEqualToString:self.selectedScheme]) {
                        int index = [self.listOfSchemes indexOfObject:str];
                        self.selectedWeapon = str;
                        self.lastIndexPath_we = [NSIndexPath indexPathForRow:index inSection:1];
                        [self.tableView reloadData];
                        break;
                    }
                }
            }
        } else {
            self.lastIndexPath_we = indexPath;
            self.selectedWeapon = [self.listOfWeapons objectAtIndex:newRow];
        }

        [aTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) fillSections {
    if (hideSections == YES) {
        hideSections = NO;
        NSRange range;
        range.location = 0;
        range.length = 3;
        NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationFade];
        self.selectedScheme = @"Default.plist";
        self.selectedWeapon = @"Default.plist";

        self.tableView.scrollEnabled = YES;

        [[self.view viewWithTag:LABEL_TAG] removeFromSuperview];
    }
}

-(void) emptySections {
    hideSections = YES;
    NSRange range;
    range.location = 0;
    range.length = 3;
    NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationFade];
    self.selectedScheme = @"Default.plist";
    self.selectedWeapon = @"Default.plist";

    self.tableView.scrollEnabled = NO;

    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width * 80/100, 60);
    UILabel *theLabel = createBlueLabel(NSLocalizedString(@"Missions don't need further configuration",@""), frame);
    theLabel.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    theLabel.numberOfLines = 2;
    theLabel.tag = LABEL_TAG;

    [self.view addSubview:theLabel];
    [theLabel release];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    if ([[SDLUIKitDelegate sharedAppDelegate] isInGame]) {
        self.lastIndexPath_sc = nil;
        self.lastIndexPath_we = nil;
        self.listOfSchemes = nil;
        self.listOfWeapons = nil;
        self.syncSwitch = nil;
        MSG_MEMCLEAN();
    }
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.listOfSchemes = nil;
    self.listOfWeapons = nil;
    self.lastIndexPath_sc = nil;
    self.lastIndexPath_we = nil;
    self.selectedScheme = nil;
    self.selectedWeapon = nil;
    self.syncSwitch = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc {
    [listOfSchemes release];
    [listOfWeapons release];
    [lastIndexPath_sc release];
    [lastIndexPath_we release];
    [selectedScheme release];
    [selectedWeapon release];
    [syncSwitch release];
    [super dealloc];
}


@end

