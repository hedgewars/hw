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


#import "FlagsViewController.h"
#import <QuartzCore/QuartzCore.h>


@implementation FlagsViewController
@synthesize teamDictionary, flagArray, communityArray, lastIndexPath;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *array_na = [[NSMutableArray alloc] init];
    NSMutableArray *array_cm = [[NSMutableArray alloc] init];

    for (NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:FLAGS_DIRECTORY() error:NULL]) {
        if ([name hasPrefix:@"cm_"]) {
            NSString *processed = [name substringFromIndex:3];
            [array_cm addObject:processed];
        } else
             [array_na addObject:name];
    }

    self.flagArray = array_na;
    [array_na release];
    self.communityArray = array_cm;
    [array_cm release];

    self.title = NSLocalizedString(@"Set team flag",@"");
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // reloadData needed because team might change
    [self.tableView reloadData];
    //[self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.flagArray count];
    else
        return [self.communityArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = [indexPath row];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSString *flagName = nil;
    NSArray *source = nil;
    if ([indexPath section] == 0) {
        source = self.flagArray;
        flagName = [source objectAtIndex:row];
    } else {
        source = self.communityArray;
        flagName = [NSString stringWithFormat:@"cm_%@",[source objectAtIndex:row]];
    }
    NSString *flagFile = [[NSString alloc] initWithFormat:@"%@/%@", FLAGS_DIRECTORY(), flagName];
    UIImage *flagSprite = [[UIImage alloc] initWithContentsOfFile:flagFile];
    [flagFile release];
    cell.imageView.image = flagSprite;
    [flagSprite release];
    cell.imageView.layer.borderWidth = 1;
    cell.imageView.layer.borderColor = [[UIColor blackColor] CGColor];

    cell.textLabel.text = [[source objectAtIndex:row] stringByDeletingPathExtension];
    if ([[flagName stringByDeletingPathExtension] isEqualToString:[self.teamDictionary objectForKey:@"flag"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

-(NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = NSLocalizedString(@"Worldwide", @"");
            break;
        case 1:
            sectionTitle = NSLocalizedString(@"Community", @"");
            break;
        default:
            DLog(@"nope");
            break;
    }
    return sectionTitle;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    NSInteger newSection = [indexPath section];
    NSInteger oldSection = (lastIndexPath != nil) ? [lastIndexPath section] : -1;

    if (newRow != oldRow || newSection != oldSection) {
        NSString *flag = nil;
        if ([indexPath section] == 0)
            flag = [self.flagArray objectAtIndex:newRow];
        else
            flag = [NSString stringWithFormat:@"cm_%@",[self.communityArray objectAtIndex:newRow]];

        // if the two selected rows differ update data on the hog dictionary and reload table content
        [self.teamDictionary setValue:[flag stringByDeletingPathExtension] forKey:@"flag"];

        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];

        UITableViewCell *newCell = [aTableView cellForRowAtIndexPath:indexPath];
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        UITableViewCell *oldCell = [aTableView cellForRowAtIndexPath:lastIndexPath];
        oldCell.accessoryType = UITableViewCellAccessoryNone;
        self.lastIndexPath = indexPath;
        [aTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    self.lastIndexPath = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.teamDictionary = nil;
    self.lastIndexPath = nil;
    self.flagArray = nil;
    self.communityArray = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(teamDictionary);
    releaseAndNil(lastIndexPath);
    releaseAndNil(flagArray);
    releaseAndNil(communityArray);
    [super dealloc];
}


@end

