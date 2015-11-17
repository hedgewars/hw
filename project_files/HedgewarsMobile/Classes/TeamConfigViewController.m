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


#import "TeamConfigViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SquareButtonView.h"


@implementation TeamConfigViewController
@synthesize tableView, selectedTeamsCount, allTeamsCount, listOfAllTeams, listOfSelectedTeams, cachedContentsOfDir;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    UITableView *aTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                                                           style:UITableViewStyleGrouped];
    aTableView.delegate = self;
    aTableView.dataSource = self;
    if (IS_IPAD()) {
        [aTableView setBackgroundColorForAnyTable:[UIColor darkBlueColorTransparent]];
        aTableView.layer.borderColor = [[UIColor darkYellowColor] CGColor];
        aTableView.layer.borderWidth = 2.7f;
        aTableView.layer.cornerRadius = 8;
        aTableView.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);
    } else {
        UIImage *backgroundImage = [[UIImage alloc] initWithContentsOfFile:@"background~iphone.png"];
        UIImageView *background = [[UIImageView alloc] initWithImage:backgroundImage];
        background.contentMode = UIViewContentModeScaleAspectFill;
        background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [backgroundImage release];
        [self.view addSubview:background];
        [background release];
        [aTableView setBackgroundColorForAnyTable:[UIColor clearColor]];
    }

    aTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    aTableView.separatorColor = [UIColor whiteColor];
    aTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    aTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView = aTableView;
    [aTableView release];

    [self.view addSubview:self.tableView];
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TEAMS_DIRECTORY() error:NULL];
    if ([self.cachedContentsOfDir isEqualToArray:contentsOfDir] == NO) {
        self.cachedContentsOfDir = contentsOfDir;
        NSArray *colors = [HWUtils teamColors];
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[contentsOfDir count]];
        for (NSUInteger i = 0; i < [contentsOfDir count]; i++) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         [contentsOfDir objectAtIndex:i],@"team",
                                         [NSNumber numberWithInt:4],@"number",
                                         [colors objectAtIndex:i%[colors count]],@"color",nil];
            [array addObject:dict];
            [dict release];
        }
        self.listOfAllTeams = array;
        [array release];

        NSMutableArray *emptyArray = [[NSMutableArray alloc] initWithObjects:nil];
        self.listOfSelectedTeams = emptyArray;
        [emptyArray release];

        self.selectedTeamsCount = [self.listOfSelectedTeams count];
        self.allTeamsCount = [self.listOfAllTeams count];
        [self.tableView reloadData];
    }

    [super viewWillAppear:animated];
}

-(NSInteger) filterNumberOfHogs:(NSInteger) hogs {
    NSInteger numberOfHogs;
    if (hogs <= HW_getMaxNumberOfHogs() && hogs >= 1)
        numberOfHogs = hogs;
    else {
        if (hogs > HW_getMaxNumberOfHogs())
            numberOfHogs = 1;
        else
            numberOfHogs = HW_getMaxNumberOfHogs();
    }
    return numberOfHogs;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0 ? self.selectedTeamsCount : self.allTeamsCount);
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";
    NSInteger section = [indexPath section];
    UITableViewCell *cell;

    if (section == 0) {
        cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
        if (cell == nil) {
            cell = [[[HoldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier0] autorelease];

            SquareButtonView *squareButton = [[SquareButtonView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
            cell.accessoryView = squareButton;
            [squareButton release];
        }

        NSMutableDictionary *selectedRow = [listOfSelectedTeams objectAtIndex:[indexPath row]];
        cell.textLabel.text = [[selectedRow objectForKey:@"team"] stringByDeletingPathExtension];
        cell.textLabel.backgroundColor = [UIColor clearColor];

        SquareButtonView *squareButton = (SquareButtonView *)cell.accessoryView;
        [squareButton selectColor:[[selectedRow objectForKey:@"color"] intValue]];
        NSNumber *hogNumber = [selectedRow objectForKey:@"number"];
        [squareButton setTitle:[hogNumber stringValue] forState:UIControlStateNormal];
        squareButton.ownerDictionary = selectedRow;

        cell.imageView.image = [UIImage drawHogsRepeated:[hogNumber intValue]];
        ((HoldTableViewCell *)cell).delegate = self;
    } else {
        cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];

        cell.textLabel.text = [[[self.listOfAllTeams objectAtIndex:[indexPath row]] objectForKey:@"team"] stringByDeletingPathExtension];
        cell.textLabel.backgroundColor = [UIColor clearColor];

        NSString *teamPath = [NSString stringWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),cell.textLabel.text];
        NSDictionary *firstHog = [[[NSDictionary dictionaryWithContentsOfFile:teamPath] objectForKey:@"hedgehogs"] objectAtIndex:0];
        if ([[firstHog objectForKey:@"level"] intValue] != 0) {
            NSString *imgString = [[NSString alloc] initWithFormat:@"%@/robotBadge.png",[[NSBundle mainBundle] resourcePath]];
            UIImage *sprite = [[UIImage alloc] initWithContentsOfFile:imgString];
            [imgString release];
            UIImageView *spriteView = [[UIImageView alloc] initWithImage:sprite];
            [sprite release];

            cell.accessoryView = spriteView;
            [spriteView release];
        } else
            cell.accessoryView = nil;
    }

    cell.textLabel.textColor = [UIColor lightYellowColor];
    cell.backgroundColor = [UIColor blackColorTransparent];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0;
}

-(UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width * 70/100, 30);
    NSString *text = (section == 0) ? NSLocalizedString(@"Playing Teams",@"") : NSLocalizedString(@"Available Teams",@"");
    UILabel *theLabel = [[UILabel alloc] initWithFrame:frame andTitle:text];
    theLabel.center = CGPointMake(self.view.frame.size.width/2, 20);
    theLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    UIView *theView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, aTableView.frame.size.width, 30)];
    theView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [theView addSubview:theLabel];
    [theLabel release];
    return [theView autorelease];
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return IS_IPAD() ? 40 : 30;
}

-(UIView *)tableView:(UITableView *)aTableView viewForFooterInSection:(NSInteger) section {
    NSInteger height = IS_IPAD() ? 40 : 30;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, aTableView.frame.size.width, height)];
    footer.backgroundColor = [UIColor clearColor];
    footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, aTableView.frame.size.width*90/100, height)];
    label.center = CGPointMake(aTableView.frame.size.width/2, height/2);
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont italicSystemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 2;
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;

    if (section == 0)
        label.text = NSLocalizedString(@"Tap to add hogs or change color, touch and hold to remove a team.",@"");
    else
        label.text = NSLocalizedString(@"The robot badge indicates an AI-controlled team.",@"");

    [footer addSubview:label];
    [label release];
    return [footer autorelease];
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];

    if (section == 1 && [self.listOfAllTeams count] > row) {
        [self.listOfSelectedTeams addObject:[self.listOfAllTeams objectAtIndex:row]];
        [self.listOfAllTeams removeObjectAtIndex:row];

        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:selectedTeamsCount inSection:0];
        allTeamsCount--;
        selectedTeamsCount++;
        [aTableView beginUpdates];
        [aTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationRight];
        [aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        [aTableView endUpdates];
    }
    if (section == 0 && [self.listOfSelectedTeams count] > row) {
        NSMutableDictionary *selectedRow = [self.listOfSelectedTeams objectAtIndex:row];
        UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
        SquareButtonView *squareButton = (SquareButtonView *)cell.accessoryView;

        NSInteger increaseNumber = [[selectedRow objectForKey:@"number"] intValue] + 1;
        NSNumber *newNumber = [NSNumber numberWithInteger:[self filterNumberOfHogs:increaseNumber]];
        [squareButton setTitle:[newNumber stringValue] forState:UIControlStateNormal];
        [selectedRow setObject:newNumber forKey:@"number"];

        cell.imageView.image = [UIImage drawHogsRepeated:[newNumber intValue]];
    }
}

-(void) holdAction:(NSString *)content onTable:(UITableView *)aTableView {
    NSUInteger row;
    for (row = 0; row < [self.listOfSelectedTeams count]; row++) {
        NSDictionary *dict = [self.listOfSelectedTeams objectAtIndex:row];
        if ([content isEqualToString:[[dict objectForKey:@"team"] stringByDeletingPathExtension]])
            break;
    }

    [self.listOfAllTeams addObject:[self.listOfSelectedTeams objectAtIndex:row]];
    [self.listOfSelectedTeams removeObjectAtIndex:row];

    [aTableView beginUpdates];
    [aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    [aTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:allTeamsCount inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
    self.allTeamsCount++;
    self.selectedTeamsCount--;
    [aTableView endUpdates];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    self.cachedContentsOfDir = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.tableView = nil;
    self.listOfAllTeams = nil;
    self.listOfSelectedTeams = nil;
    self.cachedContentsOfDir = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc {
    releaseAndNil(tableView);
    releaseAndNil(listOfAllTeams);
    releaseAndNil(listOfSelectedTeams);
    releaseAndNil(cachedContentsOfDir);
    [super dealloc];
}


@end

