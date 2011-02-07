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
@synthesize statsArray;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) viewDidLoad {
    if ([self.tableView respondsToSelector:@selector(setBackgroundView:)])
        self.tableView.backgroundView = nil;

    NSString *imgName;
    if (IS_IPAD())
        imgName = @"mediumBackground~ipad.png";
    else
        imgName = @"smallerBackground~iphone.png";

    if ([self.tableView respondsToSelector:@selector(setBackgroundView:)]) {
        UIImage *backgroundImage = [[UIImage alloc] initWithContentsOfFile:imgName];
        UIImageView *background = [[UIImageView alloc] initWithImage:backgroundImage];
        [backgroundImage release];
        [self.tableView setBackgroundView:background];
        [background release];
    } else
        self.view.backgroundColor = [UIColor blackColor];

    self.tableView.separatorColor = UICOLOR_HW_YELLOW_BODER;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [super viewDidLoad];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 || section == 3)
        return 1;
    else if (section == 1)
        return [[self.statsArray objectAtIndex:0] count];
    else
        return [self.statsArray count] - 2;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    NSString *imgString = @"";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier0] autorelease];

    if (section == 0) {         // winning team
        imgString = @"StatsStar";
        cell.textLabel.text = [self.statsArray objectAtIndex:1];
        cell.textLabel.textColor = UICOLOR_HW_YELLOW_TEXT;
    } else if (section == 1) {  // teams ranking
        // color, # kills, teamname
        NSArray *info = [[[self.statsArray objectAtIndex:0] objectAtIndex:row] componentsSeparatedByString:@" "];
        NSUInteger color = [[info objectAtIndex:0] intValue];
        cell.textLabel.textColor = [UIColor colorWithRed:((color >> 16) & 0xFF)/255.0f
                                                   green:((color >> 8) & 0xFF)/255.0f
                                                    blue:(color & 0xFF)/255.0f
                                                   alpha:1.0f];
        cell.textLabel.text = [NSString stringWithFormat:@"%d. %@ (%@ kills)", row+1, [info objectAtIndex:2], [info objectAtIndex:1]];
        imgString = [NSString stringWithFormat:@"StatsMedal%d",row+1];
    } else if (section == 2) {  // general info
        imgString = @"iconDamage";
        cell.textLabel.text = [self.statsArray objectAtIndex:row + 2];
        cell.textLabel.textColor = UICOLOR_HW_YELLOW_TEXT;
    } else {                    // exit button
        cell.textLabel.text = NSLocalizedString(@"Done",@"");
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.accessoryView = nil;
        cell.imageView.image = nil;
    }

    UIImage *img = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png",BTN_DIRECTORY(),imgString]];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    cell.imageView.image = img;
    [img release];
    cell.accessoryView = imgView;
    [imgView release];

    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.backgroundColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 160;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 160)];
        UIImage *img = [[UIImage alloc] initWithContentsOfFile:@"smallerTitle.png"];
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        [img release];
        imgView.center = CGPointMake(self.tableView.frame.size.height/2, 160/2);
        [header addSubview:imgView];
        [imgView release];

        return [header autorelease];
    } else
        return nil;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 3) {
        playSound(@"backSound");
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    self.statsArray = nil;
}

-(void) dealloc {
    [statsArray release];
    [super dealloc];
}


@end

