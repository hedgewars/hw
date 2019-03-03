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
@synthesize teamDictionary, hatArray, normalHogSprite, selectedHog;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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
    NSString *normalHogFile = [[NSString alloc] initWithFormat:@"%@/basehat-hedgehog.png",[[NSBundle mainBundle] resourcePath]];
    UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:normalHogFile];
    self.normalHogSprite = hogSprite;

    self.title = NSLocalizedString(@"Change hedgehogs' hat",@"");
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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.hatArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    NSString *hat = [self.hatArray objectAtIndex:[indexPath row]];
    cell.textLabel.text = [hat stringByDeletingPathExtension];

    NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@", HATS_DIRECTORY(), hat];
    UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile: hatFile andCutAt:CGRectMake(0, 0, 32, 32)];
    cell.imageView.image = [self.normalHogSprite mergeWith:hatSprite atPoint:CGPointMake(0, 5)];

    NSDictionary *hog = (self.selectedHog != -1) ? [[self.teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:self.selectedHog] : nil;
    if ([[hat stringByDeletingPathExtension] isEqualToString:[hog objectForKey:@"hat"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


#pragma mark -
#pragma mark Table view delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger selectedRow = [indexPath row];
    NSString *newHat = [[self.hatArray objectAtIndex:selectedRow] stringByDeletingPathExtension];
    
    // update data on the hogs dictionary
    if (self.selectedHog != -1)
    {
        // update only selected hog with new hat
        [self updateTeamDictionaryWithNewHat:newHat forStartHogIndex:self.selectedHog toEndHogIndex:self.selectedHog];
    }
    else
    {
        // update all hogs with new hat
        NSInteger startIndex = 0;
        NSInteger endIndex = [[self.teamDictionary objectForKey:@"hedgehogs"] count] - 1;
        [self updateTeamDictionaryWithNewHat:newHat forStartHogIndex:startIndex toEndHogIndex:endIndex];
    }

    // tell our boss to write this new stuff on disk
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateTeamDictionaryWithNewHat:(NSString *)newHat forStartHogIndex:(NSInteger)startIndex toEndHogIndex:(NSInteger)endIndex
{
    NSMutableArray *hogsArray = [self.teamDictionary objectForKey:@"hedgehogs"];
    
    for (NSInteger i=startIndex; i <= endIndex; i++)
    {
        NSDictionary *oldHog = [hogsArray objectAtIndex:i];
        NSMutableDictionary *newHog = [[NSMutableDictionary alloc] initWithDictionary:oldHog];
        [newHog setObject:newHat forKey:@"hat"];
        [hogsArray replaceObjectAtIndex:i withObject:newHog];
    }
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

@end

