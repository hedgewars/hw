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


#import "HogHatViewController.h"


@implementation HogHatViewController
@synthesize teamDictionary, hatArray, normalHogSprite, lastIndexPath, selectedHog;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    // load all the hat file names and store them into hatArray
    NSString *hatsDirectory = HATS_DIRECTORY();
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:hatsDirectory error:NULL];
    self.hatArray = array;

    // load the base hog image, drawing will occure in cellForRow...
    NSString *normalHogFile = [[NSString alloc] initWithFormat:@"%@/basehat-hedgehog.png",[[NSBundle mainBundle] resourcePath]];
    UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:normalHogFile];
    [normalHogFile release];
    self.normalHogSprite = hogSprite;
    [hogSprite release];

    self.title = NSLocalizedString(@"Change hedgehogs' hat",@"");
}

-(void) viewWillAppear:(BOOL)animated {
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
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

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
    cell.imageView.image = [self.normalHogSprite mergeWith:hatSprite atPoint:CGPointMake(0, 5)];
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
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

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
-(void) didReceiveMemoryWarning {
    self.lastIndexPath = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.lastIndexPath = nil;
    self.normalHogSprite = nil;
    self.teamDictionary = nil;
    self.hatArray = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(hatArray);
    releaseAndNil(teamDictionary);
    releaseAndNil(normalHogSprite);
    releaseAndNil(lastIndexPath);
    [super dealloc];
}


@end

