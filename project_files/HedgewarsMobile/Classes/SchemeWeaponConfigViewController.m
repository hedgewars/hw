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

@implementation SchemeWeaponConfigViewController
@synthesize listOfSchemes, listOfWeapons, lastIndexPath_sc, lastIndexPath_we, selectedScheme, selectedWeapon;

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

    if ([UITableView respondsToSelector:@selector(setBackgroundView:)])
         [self.tableView setBackgroundView:nil];
    self.view.backgroundColor = [UIColor clearColor];
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
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.listOfSchemes count];
    else
        return [self.listOfWeapons count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = [indexPath row];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];

    cell.accessoryView = nil;
    if ([indexPath section] == 0) {
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
    } else {
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
    }
    
    cell.backgroundColor = [UIColor blackColor];
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
    else
        text = NSLocalizedString(@"Weapons",@"");
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
        } else {
            self.lastIndexPath_we = indexPath;
            self.selectedWeapon = [self.listOfWeapons objectAtIndex:newRow];
        }

        [aTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    if ([[SDLUIKitDelegate sharedAppDelegate] isInGame]) {
        self.lastIndexPath_sc = nil;
        self.lastIndexPath_we = nil;
        self.listOfSchemes = nil;
        self.listOfWeapons = nil;
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
    [super dealloc];
}


@end

