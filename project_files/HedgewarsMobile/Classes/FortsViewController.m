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


#import "FortsViewController.h"


#define IMGNUM_PER_FORT 6

@implementation FortsViewController
@synthesize teamDictionary, fortArray, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:FORTS_DIRECTORY() error:NULL];
    NSMutableArray *filteredContents = [[NSMutableArray alloc] initWithCapacity:([directoryContents count] / IMGNUM_PER_FORT)];
    // we need to remove the double entries and the L.png suffix
    for (NSUInteger i = 0; i < [directoryContents count]; i++) {
        if (i % IMGNUM_PER_FORT == IMGNUM_PER_FORT-1) {
            NSString *currentName = [directoryContents objectAtIndex:i];
            NSString *correctName = [currentName substringToIndex:([currentName length] - 5)];
            [filteredContents addObject:correctName];
        }
    }
    self.fortArray = filteredContents;
    [filteredContents release];

    // statically set row height instead of using delegate method for performance reasons
    self.tableView.rowHeight = 128;

    self.title = NSLocalizedString(@"Choose team fort",@"");
}


-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fortArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];

    NSString *fortName = [fortArray objectAtIndex:[indexPath row]];
    cell.textLabel.text = fortName;

    NSString *fortFile = [[NSString alloc] initWithFormat:@"%@/%@-preview.png", FORTS_DIRECTORY(), fortName];
    UIImage *fortSprite = [[UIImage alloc] initWithContentsOfFile:fortFile];
    [fortFile release];
    cell.imageView.image = fortSprite;
    [fortSprite release];

    //cell.detailTextLabel.text = @"Insert funny description here";
    if ([cell.textLabel.text isEqualToString:[self.teamDictionary objectForKey:@"fort"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        // if the two selected rows differ update data on the hog dictionary and reload table content
        [self.teamDictionary setValue:[fortArray objectAtIndex:newRow] forKey:@"fort"];

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
    self.fortArray = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc {
    releaseAndNil(teamDictionary);
    releaseAndNil(lastIndexPath);
    releaseAndNil(fortArray);
    [super dealloc];
}


@end

