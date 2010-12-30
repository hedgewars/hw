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
 * File created on 30/12/2010.
 */


#import "StatsPageViewController.h"
#import "CommodityFunctions.h"

@implementation StatsPageViewController
@synthesize statsDictionary;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [[self.statsDictionary allValues] count];
    else
        return 1;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier0] autorelease];

    cell.textLabel.textAlignment = UITextAlignmentCenter;
    if ([indexPath section] == 0) {
        cell.textLabel.text = [[self.statsDictionary allValues] objectAtIndex:[indexPath row]];
    } else {
        cell.textLabel.text = NSLocalizedString(@"Back",@"");
    }

    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 2)
        [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

-(void) dealloc {
    [statsDictionary release];
    [super dealloc];
}


@end

