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
 * File created on 02/04/2010.
 */


#import "HogHatViewController.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

@implementation HogHatViewController
@synthesize teamDictionary, hatArray, normalHogSprite, lastIndexPath, selectedHog;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // load all the hat file names and store them into hatArray
    NSString *hatsDirectory = HATS_DIRECTORY();
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:hatsDirectory error:NULL];
    self.hatArray = array;

    // load the base hog image, drawing will occure in cellForRow...
    NSString *normalHogFile = [[NSString alloc] initWithFormat:@"%@/Hedgehog.png",GRAPHICS_DIRECTORY()];
    UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:normalHogFile andCutAt:CGRectMake(96, 0, 32, 32)];
    [normalHogFile release];
    self.normalHogSprite = hogSprite;
    [hogSprite release];

    self.title = NSLocalizedString(@"Change hedgehog's hat",@"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // this updates the hog name and its hat
    [self.tableView reloadData];
    // this moves the tableview to the top
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.hatArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    NSDictionary *hog = [[self.teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:selectedHog];
    NSString *hat = [hatArray objectAtIndex:[indexPath row]];
    cell.textLabel.text = [hat stringByDeletingPathExtension];

    NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@", HATS_DIRECTORY(), hat];
    UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile: hatFile andCutAt:CGRectMake(0, 0, 32, 32)];
    [hatFile release];
    cell.imageView.image = [self.normalHogSprite mergeWith:hatSprite atPoint:CGPointMake(0, -5)];
    [hatSprite release];

    if ([hat isEqualToString:[hog objectForKey:@"hat"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


#pragma mark -
#pragma mark Table view delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        // if the two selected rows differ update data on the hog dictionary and reload table content
        // TODO: maybe this section could be cleaned up
        NSDictionary *oldHog = [[teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:selectedHog];

        NSMutableDictionary *newHog = [[NSMutableDictionary alloc] initWithDictionary: oldHog];
        [newHog setObject:[[hatArray objectAtIndex:newRow] stringByDeletingPathExtension] forKey:@"hat"];
        [[teamDictionary objectForKey:@"hedgehogs"] replaceObjectAtIndex:selectedHog withObject:newHog];
        [newHog release];

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
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.lastIndexPath = nil;
    self.normalHogSprite = nil;
    self.teamDictionary = nil;
    self.hatArray = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

- (void)dealloc {
    [hatArray release];
    [teamDictionary release];
    [normalHogSprite release];
    [lastIndexPath release];
    [super dealloc];
}


@end

