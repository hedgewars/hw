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


#import "GravesViewController.h"


@implementation GravesViewController
@synthesize teamDictionary, graveArray, lastIndexPath;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // load all the grave names and store them into graveArray
    self.graveArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:GRAVES_DIRECTORY() error:NULL];

    self.title = NSLocalizedString(@"Choose hedgehog graves",@"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    // this moves the tableview to the top
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}


#pragma mark -
#pragma mark Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.graveArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    NSString *grave = [self.graveArray objectAtIndex:[indexPath row]];
    cell.textLabel.text = [grave stringByDeletingPathExtension];

    if ([grave isEqualToString:[self.teamDictionary objectForKey:@"grave"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    NSString *graveFilePath = [[NSString alloc] initWithFormat:@"%@/%@",GRAVES_DIRECTORY(),grave];
    // because we also have multi frame graves, let's take the first one only
    UIImage *graveSprite = [[UIImage alloc] initWithContentsOfFile:graveFilePath andCutAt:CGRectMake(0, 0, 32, 32)];
    cell.imageView.image = graveSprite;

    return cell;
}


#pragma mark -
#pragma mark Table view delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        [teamDictionary setObject:[[graveArray objectAtIndex:newRow] stringByDeletingPathExtension] forKey:@"grave"];

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

- (void)didReceiveMemoryWarning {
    self.lastIndexPath = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

@end

