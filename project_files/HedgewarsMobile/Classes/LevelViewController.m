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


#import "LevelViewController.h"


@implementation LevelViewController
@synthesize teamDictionary, levelArray, levelSprites, lastIndexPath;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];
    srandom(time(NULL));

    NSArray *array = [[NSArray alloc] initWithObjects:
                      NSLocalizedString(@"Brutal",@""),
                      NSLocalizedString(@"Aggressive",@""),
                      NSLocalizedString(@"Bully",@""),
                      NSLocalizedString(@"Average",@""),
                      NSLocalizedString(@"Weaky",@""),
                      nil];
    self.levelArray = array;
    [array release];

    self.title = NSLocalizedString(@"Set difficulty level",@"");
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([[[[self.teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:0] objectForKey:@"level"] intValue] == 0)
        numberOfSections = 1;
    else
        numberOfSections = 2;

    [self.tableView reloadData];
    // this moves the tableview to the top
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}

-(void) viewWillDisappear:(BOOL)animated {
 // stuff like checking that at least 1 field was selected
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return numberOfSections;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section {
    if (section == 0)
        return 1;
    else
        return 5;
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";

    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    UITableViewCell *cell;

    if (section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier0];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier0] autorelease];
            UISwitch *theSwitch = [[UISwitch alloc] init];
            [theSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = theSwitch;
            [theSwitch release];
        }
        UISwitch *theSwitch = (UISwitch *)cell.accessoryView;
        if (numberOfSections == 1)
            theSwitch.on = NO;
        else
            theSwitch.on = YES;
        cell.textLabel.text = NSLocalizedString(@"Hogs controlled by AI",@"");
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];

        cell.textLabel.text = [levelArray objectAtIndex:row];
        NSDictionary *hog = [[self.teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:0];
        if ([[hog objectForKey:@"level"] intValue] == row+1) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.lastIndexPath = indexPath;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        NSString *botlevelPath = [[NSString alloc] initWithFormat:@"%@/bot%d.png",[[NSBundle mainBundle] resourcePath],row+1];
        UIImage *levelImage = [[UIImage alloc] initWithContentsOfFile:botlevelPath];
        [botlevelPath release];
        cell.imageView.image = levelImage;
        [levelImage release];
    }

    return cell;
}

-(void) switchValueChanged:(id) sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    NSIndexSet *sections = [[NSIndexSet alloc] initWithIndex:1];
    NSMutableArray *hogs = [self.teamDictionary objectForKey:@"hedgehogs"];
    NSInteger level;

    if (theSwitch.on) {
        numberOfSections = 2;
        [self.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationFade];
        level = 1 + (random() % ([levelArray count] - 1));
    } else {
        numberOfSections = 1;
        [self.tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationFade];
        level = 0;
    }
    [sections release];

    DLog(@"New level is %ld", (long)level);
    for (NSMutableDictionary *hog in hogs)
        [hog setObject:[NSNumber numberWithInteger:level] forKey:@"level"];

    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (self.lastIndexPath != nil) ? [self.lastIndexPath row] : -1;

    if ([indexPath section] != 0) {
        if (newRow != oldRow) {
            NSMutableArray *hogs = [self.teamDictionary objectForKey:@"hedgehogs"];

            NSInteger level = newRow + 1;
            for (NSMutableDictionary *hog in hogs)
                [hog setObject:[NSNumber numberWithInteger:level] forKey:@"level"];
            DLog(@"New level is %ld", (long)level);

            // tell our boss to write this new stuff on disk
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
            [self.tableView reloadData];

            self.lastIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    self.teamDictionary = nil;
    self.levelArray = nil;
    self.levelSprites = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(levelArray);
    releaseAndNil(levelSprites);
    releaseAndNil(teamDictionary);
    releaseAndNil(lastIndexPath);
    [super dealloc];
}


@end

