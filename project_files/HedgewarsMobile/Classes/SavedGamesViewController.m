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
 * File created on 22/09/2010.
 */


#import "SavedGamesViewController.h"
#import "SDL_uikitappdelegate.h"
#import "CommodityFunctions.h"

@implementation SavedGamesViewController
@synthesize tableView, listOfSavegames;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) viewDidLoad {
    self.tableView.backgroundView = nil;

    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:SAVES_DIRECTORY() error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:contentsOfDir copyItems:YES];
    self.listOfSavegames = array;
    [array release];

    [self.tableView reloadData];    
}

-(IBAction) buttonPressed:(id) sender {
    playSound(@"backSound");
    [[self parentViewController] dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfSavegames count];
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];

    // first all the names, then the title (which is offset 5)
    cell.textLabel.text = [[self.listOfSavegames objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",SAVES_DIRECTORY(),[self.listOfSavegames objectAtIndex:[indexPath row]]];
    
    NSDictionary *allDataNecessary = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSDictionary dictionary],@"game_dictionary",
                                      filePath,@"savefile",
                                      [NSNumber numberWithBool:NO],@"netgame",
                                      nil];
    [[SDLUIKitDelegate sharedAppDelegate] startSDLgame:allDataNecessary];
}

#pragma mark -
#pragma mark Memory Management
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.tableView = nil;
    self.listOfSavegames = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [tableView release];
    [listOfSavegames release];
    [super dealloc];
}

@end
