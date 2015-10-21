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


#import "StatsPageViewController.h"


@implementation StatsPageViewController
@synthesize statsArray;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) viewDidLoad {
    UITableView *aTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    aTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [aTableView setBackgroundColorForAnyTable:[UIColor clearColor]];

    NSString *imgName = (IS_IPAD()) ? @"mediumBackground~ipad.png" : @"smallerBackground~iphone.png";
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgName];
    UIImageView *background = [[UIImageView alloc] initWithImage:img];
    [img release];
    background.frame = self.view.frame;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:background atIndex:0];
    [background release];

    aTableView.separatorColor = [UIColor darkYellowColor];
    aTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    aTableView.delegate = self;
    aTableView.dataSource = self;
    
    aTableView.rowHeight = 44;
    
    [self.view addSubview:aTableView];
    [aTableView release];

    [super viewDidLoad];
}

#pragma mark - Helpers

- (NSString *)teamNameFromInfo: (NSArray *)info
{
    NSString *teamName = [NSString stringWithString:[info objectAtIndex:2]];
    
    for (int i=3; i < [info count]; i++)
    {
        teamName = [teamName stringByAppendingFormat:@" %@", [info objectAtIndex:i]];
    }
    
    return teamName;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
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
    NSString *imgName = @"";
    NSString *imgPath = ICONS_DIRECTORY();

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier0] autorelease];

    if (section == 0) {         // winning team
        imgName = @"star";
        imgPath = [[NSBundle mainBundle] resourcePath];
        cell.textLabel.text = [self.statsArray objectAtIndex:1];
        cell.textLabel.textColor = [UIColor lightYellowColor];
    } else if (section == 1) {  // teams ranking
        // color, # kills, teamname
        NSArray *info = [[[self.statsArray objectAtIndex:0] objectAtIndex:row] componentsSeparatedByString:@" "];
        NSUInteger color = [[info objectAtIndex:0] intValue];
        cell.textLabel.textColor = [UIColor colorWithRed:((color >> 16) & 0xFF)/255.0f
                                                   green:((color >> 8) & 0xFF)/255.0f
                                                    blue:(color & 0xFF)/255.0f
                                                   alpha:1.0f];
        cell.textLabel.text = [NSString stringWithFormat:@"%d. %@ (%@ kills)", row+1, [self teamNameFromInfo:info], [info objectAtIndex:1]];
        imgName = [NSString stringWithFormat:@"StatsMedal%d",row+1];
    } else if (section == 2) {  // general info
        imgName = @"iconDamage";
        cell.textLabel.text = [self.statsArray objectAtIndex:row + 2];
        cell.textLabel.textColor = [UIColor lightYellowColor];
    }

    NSString *imgString = [[NSString alloc] initWithFormat:@"%@/%@.png",imgPath,imgName];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgString];
    [imgString release];
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

-(CGFloat) tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section {
    return (section == 0) ? 160 : 40;
}

-(UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, aTableView.frame.size.width, 160)];
        header.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIImage *img = [[UIImage alloc] initWithContentsOfFile:@"smallerTitle.png"];
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        [img release];
        imgView.center = CGPointMake(aTableView.frame.size.width/2, 160/2);
        imgView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [header addSubview:imgView];
        [imgView release];

        return [header autorelease];
    } else
        return nil;
}

-(CGFloat) tableView:(UITableView *)aTableView heightForFooterInSection:(NSInteger)section {
    return aTableView.rowHeight + 30;
}

-(UIView *)tableView:(UITableView *)aTableView viewForFooterInSection:(NSInteger)section {
    if (section == 2) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width * 70 / 100, aTableView.rowHeight)];
        footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 17, self.view.frame.size.width * 70 / 100, aTableView.rowHeight)
                                                  andTitle:NSLocalizedString(@"Done",@"")];
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [button addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
        [footer addSubview:button];
        [button release];

        return [footer autorelease];
    } else
        return nil;
}

#pragma mark -
#pragma mark button delegate
-(void) dismissView {
    [[AudioManagerController mainManager] playClickSound];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    self.statsArray = nil;
}

-(void) dealloc {
    releaseAndNil(statsArray);
    [super dealloc];
}


@end

