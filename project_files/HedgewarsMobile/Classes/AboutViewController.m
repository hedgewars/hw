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
 * File created on 01/08/2010.
 */


#import "AboutViewController.h"
#import "CommodityFunctions.h"

@implementation AboutViewController
@synthesize tableView, segmentedControl, people;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) viewDidLoad {
    self.tableView.backgroundView = nil;
    self.tableView.allowsSelection = NO;

    NSString *strPath = [NSString stringWithFormat:@"%@/credits.plist",IFRONTEND_DIRECTORY()];
    NSArray *array = [[NSArray alloc] initWithContentsOfFile:strPath];
    self.people = array;
    [array release];

    NSString *imgName;
    if (IS_IPAD())
        imgName = @"smallerBackground~ipad.png";
    else
        imgName = @"smallerBackground~iphone.png";
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgName];
    self.view.backgroundColor = [UIColor colorWithPatternImage:img];
    [img release];
    [super viewDidLoad];
}

-(IBAction) buttonPressed:(id) sender {
    playSound(@"backSound");
    [[self parentViewController] dismissModalViewControllerAnimated:YES];
}

-(IBAction) segmentedControlChanged:(id) sender {
    playSound(@"clickSound");
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.people objectAtIndex:self.segmentedControl.selectedSegmentIndex] count];
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];

    // first all the names, then the title (which is offset 5)
    cell.textLabel.text = [[self.people objectAtIndex:self.segmentedControl.selectedSegmentIndex] objectAtIndex:[indexPath row]];
    cell.detailTextLabel.text = [[self.people objectAtIndex:(self.segmentedControl.selectedSegmentIndex + 5)] objectAtIndex:[indexPath row]];

    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // do nothing
}

#pragma mark -
#pragma mark Memory Management
-(void) didReceiveMemoryWarning {
    self.people = nil;
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.tableView = nil;
    self.segmentedControl = nil;
    self.people = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [tableView release];
    [segmentedControl release];
    [people release];
    [super dealloc];
}

@end
