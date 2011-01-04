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
 * File created on 20/04/2010.
 */


#import "TeamConfigViewController.h"
#import "CommodityFunctions.h"
#import "SquareButtonView.h"

@implementation TeamConfigViewController
@synthesize listOfTeams, listOfSelectedTeams, cachedContentsOfDir;

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.view.frame = CGRectMake(0, 0, screenSize.height, screenSize.width - 44);

    if ([self.tableView respondsToSelector:@selector(setBackgroundView:)]) {
        if (IS_IPAD())
            [self.tableView setBackgroundView:nil];
        else {
            UIImage *backgroundImage = [[UIImage alloc] initWithContentsOfFile:@"background~iphone.png"];
            UIImageView *background = [[UIImageView alloc] initWithImage:backgroundImage];
            [backgroundImage release];
            [self.tableView setBackgroundView:background];
            [background release];
        }
    } else
        self.view.backgroundColor = [UIColor blackColor];

    self.tableView.separatorColor = UICOLOR_HW_YELLOW_BODER;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TEAMS_DIRECTORY() error:NULL];
    // avoid overwriting selected teams when returning on this view
    if ([self.cachedContentsOfDir isEqualToArray:contentsOfDir] == NO) {
        NSArray *colors = getAvailableColors();
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[contentsOfDir count]];
        for (int i = 0; i < [contentsOfDir count]; i++) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         [contentsOfDir objectAtIndex:i],@"team",
                                         [NSNumber numberWithInt:4],@"number",
                                         [colors objectAtIndex:i%[colors count]],@"color",nil];
            [array addObject:dict];
            [dict release];
        }
        self.listOfTeams = array;
        [array release];

        NSMutableArray *emptyArray = [[NSMutableArray alloc] initWithObjects:nil];
        self.listOfSelectedTeams = emptyArray;
        [emptyArray release];

        selectedTeamsCount = [self.listOfSelectedTeams count];
        allTeamsCount = [self.listOfTeams count];

        self.cachedContentsOfDir = [[NSArray alloc] initWithArray:contentsOfDir copyItems:YES];
    }
    [self.tableView reloadData];
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
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

-(UIImage *)drawHogsRepeated:(NSInteger) manyTimes {
    UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:HEDGEHOG_FILE()];
    CGFloat screenScale = getScreenScale();
    int w = hogSprite.size.width * screenScale;
    int h = hogSprite.size.height * screenScale;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w * 3, h, 8, 4 * w * 3, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    // draw the two images in the current context
    for (int i = 0; i < manyTimes; i++)
        CGContextDrawImage(context, CGRectMake(i*8*screenScale, 0, w, h), [hogSprite CGImage]);
    [hogSprite release];
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *resultImage;
    if ([self respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
        resultImage = [UIImage imageWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];
    else
        resultImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);

    return resultImage;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return selectedTeamsCount;
    else
        return allTeamsCount;
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

        cell.imageView.image = [self drawHogsRepeated:[hogNumber intValue]];
        ((HoldTableViewCell *)cell).delegate = self;
    } else {
        cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];

        cell.textLabel.text = [[[listOfTeams objectAtIndex:[indexPath row]] objectForKey:@"team"] stringByDeletingPathExtension];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        
        NSString *teamPath = [NSString stringWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),cell.textLabel.text];
        NSDictionary *firstHog = [[[NSDictionary dictionaryWithContentsOfFile:teamPath] objectForKey:@"hedgehogs"] objectAtIndex:0];
        if ([[firstHog objectForKey:@"level"] intValue] != 0) {
            NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Settings/Images/robotBadge.png"];
            UIImage *sprite = [[UIImage alloc] initWithContentsOfFile:filePath];
            UIImageView *spriteView = [[UIImageView alloc] initWithImage:sprite];
            [sprite release];
            
            cell.accessoryView = spriteView;
            [spriteView release];
        } else
            cell.accessoryView = nil;
    }

    cell.textLabel.textColor = UICOLOR_HW_YELLOW_TEXT;
    cell.backgroundColor = UICOLOR_HW_ALMOSTBLACK;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width * 80/100, 30);
    NSString *text;
    if (section == 0)
        text = NSLocalizedString(@"Playing Teams",@"");
    else
        text = NSLocalizedString(@"Available Teams",@"");
    UILabel *theLabel = createBlueLabel(text, frame);
    theLabel.center = CGPointMake(self.view.frame.size.width/2, 20);

    UIView *theView = [[[UIView alloc] init] autorelease];
    [theView addSubview:theLabel];
    [theLabel release];
    return theView;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return IS_IPAD() ? 40 : 20;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger) section {
    NSInteger height = IS_IPAD() ? 40 : 20;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, height)];
    footer.backgroundColor = [UIColor clearColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width*80/100, height)];
    label.center = CGPointMake(self.tableView.frame.size.width/2, height/2);
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont italicSystemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 2;
    if (section == 0)
        label.text = NSLocalizedString(@"Tap to add hogs or change color, touch and hold to remove a team.",@"");
    else
        label.text = NSLocalizedString(@"The robot badge indicates an AI-controlled team.",@"");

    label.backgroundColor = [UIColor clearColor];
    [footer addSubview:label];
    [label release];
    return [footer autorelease];
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];

    if (section == 1 && [self.listOfTeams count] > row) {
        [self.listOfSelectedTeams addObject:[self.listOfTeams objectAtIndex:row]];
        [self.listOfTeams removeObjectAtIndex:row];

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
        NSNumber *newNumber = [NSNumber numberWithInt:[self filterNumberOfHogs:increaseNumber]];
        [squareButton setTitle:[newNumber stringValue] forState:UIControlStateNormal];
        [selectedRow setObject:newNumber forKey:@"number"];

        cell.imageView.image = [self drawHogsRepeated:[newNumber intValue]];
    }
}

-(void) holdAction:(NSString *)content {
    NSInteger row;
    for (row = 0; row < [self.listOfSelectedTeams count]; row++) {
        NSDictionary *dict = [self.listOfSelectedTeams objectAtIndex:row];
        if ([content isEqualToString:[[dict objectForKey:@"team"] stringByDeletingPathExtension]])
            break;
    }

    [self.listOfTeams addObject:[self.listOfSelectedTeams objectAtIndex:row]];
    [self.listOfSelectedTeams removeObjectAtIndex:row];

    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:allTeamsCount inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
    allTeamsCount++;
    selectedTeamsCount--;
    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Relinquish ownership any cached data, images, etc that aren't in use.
    self.cachedContentsOfDir = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.listOfTeams = nil;
    self.listOfSelectedTeams = nil;
    self.cachedContentsOfDir = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc {
    [listOfTeams release];
    [listOfSelectedTeams release];
    [cachedContentsOfDir release];
    [super dealloc];
}


@end

