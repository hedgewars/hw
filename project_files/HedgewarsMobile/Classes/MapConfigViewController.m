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
 * File created on 22/04/2010.
 */


#import "MapConfigViewController.h"
#import "PascalImports.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"


@implementation MapConfigViewController
@synthesize previewButton, maxHogs, seedCommand, templateFilterCommand, mapGenCommand, mazeSizeCommand, themeCommand, staticMapCommand,
            tableView, maxLabel, sizeLabel, segmentedControl, slider, lastIndexPath, themeArray, mapArray, busy, delegate;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) mapButtonPressed {
    playSound(@"clickSound");
    [self updatePreview];
}

-(void) updatePreview {
    // don't generate a new preview while it's already generating one
    if (busy)
        return;

    // generate a seed
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *seed = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    NSString *seedCmd = [[NSString alloc] initWithFormat:@"eseed {%@}", seed];
    self.seedCommand = seedCmd;
    [seedCmd release];

    NSIndexPath *theIndex;
    if (segmentedControl.selectedSegmentIndex != 1) {
        // prevent other events and add an activity while the preview is beign generated
        [self turnOffWidgets];
        [self.previewButton updatePreviewWithSeed:seed];
        theIndex = [NSIndexPath indexPathForRow:(random()%[self.themeArray count]) inSection:0];
    } else {
        theIndex = [NSIndexPath indexPathForRow:(random()%[self.mapArray count]) inSection:0];
        // the preview for static maps is loaded in didSelectRowAtIndexPath
    }
    [seed release];

    // perform as if user clicked on an entry
    [self tableView:self.tableView didSelectRowAtIndexPath:theIndex];
    [self.tableView scrollToRowAtIndexPath:theIndex atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

-(void) turnOffWidgets {
    busy = YES;
    self.previewButton.alpha = 0.5f;
    self.previewButton.enabled = NO;
    self.maxLabel.text = @"...";
    self.segmentedControl.enabled = NO;
    self.slider.enabled = NO;
}

-(void) turnOnWidgets {
    self.previewButton.alpha = 1.0f;
    self.previewButton.enabled = YES;
    self.segmentedControl.enabled = YES;
    self.slider.enabled = YES;
    busy = NO;
}

-(void) setLabelText:(NSString *)str {
    self.maxHogs = [str intValue];
    self.maxLabel.text = str;
}

-(NSDictionary *)getDataForEngine {
    NSDictionary *dictForEngine = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.seedCommand,@"seedCommand",
                                   self.templateFilterCommand,@"templateFilterCommand",
                                   self.mapGenCommand,@"mapGenCommand",
                                   self.mazeSizeCommand,@"mazeSizeCommand",
                                   nil];
    return dictForEngine;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger) section {
    if (self.segmentedControl.selectedSegmentIndex != 1)
        return [themeArray count];
    else
        return [mapArray count];
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = [indexPath row];

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        cell.textLabel.textColor = UICOLOR_HW_YELLOW_TEXT;

    if (self.segmentedControl.selectedSegmentIndex != 1) {
        // the % prevents a strange bug that occurs sporadically
        NSString *themeName = [self.themeArray objectAtIndex:row % [self.themeArray count]];
        cell.textLabel.text = themeName;
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/icon.png",THEMES_DIRECTORY(),themeName]];
        cell.imageView.image = image;
        [image release];
    } else {
        cell.textLabel.text = [self.mapArray objectAtIndex:row];
        cell.imageView.image = nil;
    }

    if (row == [self.lastIndexPath row]) {
        UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
        cell.accessoryView = checkbox;
        [checkbox release];
    } else
        cell.accessoryView = nil;

    cell.backgroundColor = [UIColor blackColor];
    return cell;
}

// this set details for a static map (called by didSelectRowAtIndexPath)
-(void) setDetailsForStaticMap:(NSInteger) index {
    // update label
    maxHogs = 18;
    NSString *fileCfg = [[NSString alloc] initWithFormat:@"%@/%@/map.cfg", MAPS_DIRECTORY(),[self.mapArray objectAtIndex:index]];
    NSString *contents = [[NSString alloc] initWithContentsOfFile:fileCfg encoding:NSUTF8StringEncoding error:NULL];
    [fileCfg release];
    NSArray *split = [contents componentsSeparatedByString:@"\n"];
    [contents release];

    // set the theme and map here
    self.themeCommand = [NSString stringWithFormat:@"etheme %@", [split objectAtIndex:0]];
    self.staticMapCommand = [NSString stringWithFormat:@"emap %@", [self.mapArray objectAtIndex:index]];

    // if the number is not set we keep 18 standard;
    // sometimes it's not set but there are trailing characters, we get around them with the second equation
    if ([split count] > 1 && [[split objectAtIndex:1] intValue] > 0)
        maxHogs = [[split objectAtIndex:1] intValue];
    NSString *max = [[NSString alloc] initWithFormat:@"%d",maxHogs];
    self.maxLabel.text = max;
    [max release];
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        [self.tableView reloadData];
        if (self.segmentedControl.selectedSegmentIndex != 1) {
            // just change the theme, don't update preview
            self.themeCommand = [NSString stringWithFormat:@"etheme %@", [self.themeArray objectAtIndex:newRow]];
        } else {
            NSString *fileImage = [NSString stringWithFormat:@"%@/%@/preview.png",MAPS_DIRECTORY(),[self.mapArray objectAtIndex:newRow]];
            [self.previewButton updatePreviewWithFile:fileImage];
            [self setDetailsForStaticMap:newRow];
        }

        UITableViewCell *newCell = [aTableView cellForRowAtIndexPath:indexPath];
        UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
        newCell.accessoryView = checkbox;
        [checkbox release];
        UITableViewCell *oldCell = [aTableView cellForRowAtIndexPath:self.lastIndexPath];
        oldCell.accessoryView = nil;

        self.lastIndexPath = indexPath;
        [aTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark slider & segmentedControl
// this updates the label and the command keys when the slider is moved, depending of the selection in segmentedControl
// no methods are called by this routine and you can pass nil to it
-(IBAction) sliderChanged:(id) sender {
    NSString *labelText;
    NSString *templateCommand;
    NSString *mazeCommand;

    switch ((int)(self.slider.value*100)) {
        case 0:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Wacky",@"");
            } else {
                labelText = NSLocalizedString(@"Large Floating Islands",@"");
            }
            templateCommand = @"e$template_filter 5";
            mazeCommand = @"e$maze_size 5";
            break;
        case 1:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Cavern",@"");
            } else {
                labelText = NSLocalizedString(@"Medium Floating Islands",@"");
            }
            templateCommand = @"e$template_filter 4";
            mazeCommand = @"e$maze_size 4";
            break;
        case 2:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Small",@"");
            } else {
                labelText = NSLocalizedString(@"Small Floating Islands",@"");
            }
            templateCommand = @"e$template_filter 1";
            mazeCommand = @"e$maze_size 3";
            break;
        case 3:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Medium",@"");
            } else {
                labelText = NSLocalizedString(@"Large Tunnels",@"");
            }
            templateCommand = @"e$template_filter 2";
            mazeCommand = @"e$maze_size 2";
            break;
        case 4:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Large",@"");
            } else {
                labelText = NSLocalizedString(@"Medium Tunnels",@"");
            }
            templateCommand = @"e$template_filter 3";
            mazeCommand = @"e$maze_size 1";
            break;
        case 5:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"All",@"");
            } else {
                labelText = NSLocalizedString(@"Small Tunnels",@"");
            }
            templateCommand = @"e$template_filter 0";
            mazeCommand = @"e$maze_size 0";
            break;
        default:
            labelText = nil;
            templateCommand = nil;
            mazeCommand = nil;
            break;
    }

    self.sizeLabel.text = labelText;
    self.templateFilterCommand = templateCommand;
    self.mazeSizeCommand = mazeCommand;
}

// update preview (if not busy and if its value really changed) as soon as the user lifts its finger up
-(IBAction) sliderEndedChanging:(id) sender {
    int num = (int) (self.slider.value * 100);
    if (oldValue != num) {
        [self updatePreview];
        oldValue = num;
    }
    playSound(@"clickSound");
}

// perform actions based on the activated section, then call updatePreview to visually update the selection
// and if necessary update the table with a slide animation
-(IBAction) segmentedControlChanged:(id) sender {
    NSString *mapgen, *staticmap;
    NSInteger newPage = self.segmentedControl.selectedSegmentIndex;

    playSound(@"selSound");
    switch (newPage) {
        case 0: // Random
            mapgen = @"e$mapgen 0";
            staticmap = @"";
            [self sliderChanged:nil];
            self.slider.enabled = YES;
            break;

        case 1: // Map
            mapgen = @"e$mapgen 0";
            // dummy value, everything is set by -updatePreview -> -didSelectRowAtIndexPath -> -updatePreviewWithMap
            staticmap = @"map Bamboo";
            self.slider.enabled = NO;
            self.sizeLabel.text = NSLocalizedString(@"No filter",@"");
            break;

        case 2: // Maze
            mapgen = @"e$mapgen 1";
            staticmap = @"";
            [self sliderChanged:nil];
            self.slider.enabled = YES;
            break;

        default:
            mapgen = nil;
            staticmap = nil;
            break;
    }
    self.mapGenCommand = mapgen;
    self.staticMapCommand = staticmap;
    [self updatePreview];

    // nice animation for updating the table when appropriate (on iphone)
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        if (((oldPage == 0 || oldPage == 2) && newPage == 1) ||
            (oldPage == 1 && (newPage == 0 || newPage == 2))) {
            [UIView beginAnimations:@"moving out table" context:NULL];
            self.tableView.frame = CGRectMake(480, 0, 185, 276);
            [UIView commitAnimations];
            [self performSelector:@selector(moveTable) withObject:nil afterDelay:0.2];
        }
    oldPage = newPage;
}

// update data when table is not visible and then show it
-(void) moveTable {
    [self.tableView reloadData];

    [UIView beginAnimations:@"moving in table" context:NULL];
    self.tableView.frame = CGRectMake(295, 0, 185, 276);
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark view management
-(void) viewDidLoad {
    [super viewDidLoad];

    srandom(time(NULL));

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.view.frame = CGRectMake(0, 0, screenSize.height, screenSize.width - 44);

    // themes.cfg contains all the user-selectable themes
    NSString *string = [[NSString alloc] initWithContentsOfFile:[THEMES_DIRECTORY() stringByAppendingString:@"/themes.cfg"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:[string componentsSeparatedByString:@"\n"]];
    [string release];
    // remove a trailing "" element
    [array removeLastObject];
    self.themeArray = array;
    [array release];
    self.mapArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:MAPS_DIRECTORY() error:NULL];

    // initialize some "default" values
    self.sizeLabel.text = NSLocalizedString(@"All",@"");
    self.slider.value = 0.05f;

    // select a map at first because it's faster - done in IB
    //self.segmentedControl.selectedSegmentIndex = 1;
    if (self.segmentedControl.selectedSegmentIndex == 1) {
        self.slider.enabled = NO;
        self.sizeLabel.text = NSLocalizedString(@"No filter",@"");
    }

    self.templateFilterCommand = @"e$template_filter 0";
    self.mazeSizeCommand = @"e$maze_size 0";
    self.mapGenCommand = @"e$mapgen 0";
    self.staticMapCommand = @"";

    self.lastIndexPath = [NSIndexPath indexPathForRow:-1 inSection:0];

    oldValue = 5;
    oldPage = 0;
    busy = NO;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.tableView setBackgroundView:nil];
        self.view.backgroundColor = [UIColor clearColor];
        self.tableView.separatorColor = UICOLOR_HW_YELLOW_BODER;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.rowHeight = 45;
    }
}

-(void) viewDidAppear:(BOOL) animated {
    [self updatePreview];
    [super viewDidAppear:animated];
}

#pragma mark -
#pragma mark delegate functions for iPad
-(IBAction) buttonPressed:(id) sender {
    if (self.delegate != nil && [delegate respondsToSelector:@selector(buttonPressed:)])
        [self.delegate buttonPressed:(UIButton *)sender];
}

#pragma mark -
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    self.delegate = nil;
    
    self.previewButton = nil;
    self.seedCommand = nil;
    self.templateFilterCommand = nil;
    self.mapGenCommand = nil;
    self.mazeSizeCommand = nil;
    self.themeCommand = nil;
    self.staticMapCommand = nil;

    self.previewButton = nil;
    self.tableView = nil;
    self.maxLabel = nil;
    self.sizeLabel = nil;
    self.segmentedControl = nil;
    self.slider = nil;

    self.lastIndexPath = nil;
    self.themeArray = nil;
    self.mapArray = nil;

    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    self.delegate = nil;
    
    [seedCommand release];
    [templateFilterCommand release];
    [mapGenCommand release];
    [mazeSizeCommand release];
    [themeCommand release];
    [staticMapCommand release];

    [previewButton release];
    [tableView release];
    [maxLabel release];
    [sizeLabel release];
    [segmentedControl release];
    [slider release];

    [lastIndexPath release];
    [themeArray release];
    [mapArray release];

    [super dealloc];
}

@end
