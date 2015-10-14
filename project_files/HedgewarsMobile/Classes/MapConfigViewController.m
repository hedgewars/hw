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


#import "MapConfigViewController.h"
#import <QuartzCore/QuartzCore.h>


#define scIndex         self.segmentedControl.selectedSegmentIndex
#define isRandomness()  (segmentedControl.selectedSegmentIndex == 0 || segmentedControl.selectedSegmentIndex == 2)

@implementation MapConfigViewController
@synthesize previewButton, maxHogs, seedCommand, templateFilterCommand, mapGenCommand, mazeSizeCommand, themeCommand, staticMapCommand,
            missionCommand, tableView, maxLabel, segmentedControl, slider, lastIndexPath, dataSourceArray, busy,
            oldPage, oldValue;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) mapButtonPressed:(id) sender {
    [[AudioManagerController mainManager] playClickSound];
    [self updatePreview];
}

-(void) updatePreview {
    // don't generate a new preview while it's already generating one
    if (self.busy)
        return;

    // generate a seed
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *seed = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    NSString *seedCmd = [[NSString alloc] initWithFormat:@"eseed {%@}", seed];
    self.seedCommand = seedCmd;
    [seedCmd release];

    NSArray *source = [self.dataSourceArray objectAtIndex:scIndex];
    if (isRandomness()) {
        // prevent other events and add an activity while the preview is beign generated
        [self turnOffWidgets];
        [self.previewButton updatePreviewWithSeed:seed];
        // the preview for static maps is loaded in didSelectRowAtIndexPath
    }
    [seed release];

    // perform as if user clicked on an entry
    NSIndexPath *theIndex = [NSIndexPath indexPathForRow:arc4random_uniform((int)[source count]) inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:theIndex];
    if (IS_NOT_POWERFUL([HWUtils modelType]) == NO)
        [self.tableView scrollToRowAtIndexPath:theIndex atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

-(void) turnOffWidgets {
    busy = YES;
    self.previewButton.alpha = 0.5f;
    self.previewButton.enabled = NO;
    self.maxLabel.text = NSLocalizedString(@"Loading...",@"");;
    self.segmentedControl.enabled = NO;
    self.slider.enabled = NO;
}

#pragma mark -
#pragma mark MapPreviewButtonView delegate methods
-(void) turnOnWidgets {
    self.previewButton.alpha = 1.0f;
    self.previewButton.enabled = YES;
    self.segmentedControl.enabled = YES;
    self.slider.enabled = YES;
    self.busy = NO;
}

-(void) setMaxLabelText:(NSString *)str {
    self.maxHogs = [str intValue];
    self.maxLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Max Hogs:",@""),str];
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
    return [[self.dataSourceArray objectAtIndex:scIndex] count];
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSUInteger row = [indexPath row];

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    NSArray *source = [self.dataSourceArray objectAtIndex:scIndex];

    NSString *labelString = [source objectAtIndex:row];
    cell.textLabel.text = labelString;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumFontSize = 7;
    cell.textLabel.textColor = [UIColor lightYellowColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];

    if (isRandomness()) {
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/icon.png",THEMES_DIRECTORY(),labelString]];
        cell.imageView.image = image;
        [image release];
    } else
        cell.imageView.image = nil;

    if (row == [self.lastIndexPath row]) {
        UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
        cell.accessoryView = checkbox;
        [checkbox release];
    } else
        cell.accessoryView = nil;

    cell.backgroundColor = [UIColor blackColorTransparent];
    return cell;
}

// this set details for a static map (called by didSelectRowAtIndexPath)
-(void) setDetailsForStaticMap:(NSInteger) index {
    NSArray *source = [self.dataSourceArray objectAtIndex:scIndex];

    NSString *fileCfg = [[NSString alloc] initWithFormat:@"%@/%@/map.cfg",
                         (scIndex == 1) ? MAPS_DIRECTORY() : MISSIONS_DIRECTORY(),[source objectAtIndex:index]];
    NSString *contents = [[NSString alloc] initWithContentsOfFile:fileCfg encoding:NSUTF8StringEncoding error:NULL];
    [fileCfg release];
    NSArray *split = [contents componentsSeparatedByString:@"\n"];
    [contents release];

    // if the number is not set we keep 18 standard;
    // sometimes it's not set but there are trailing characters, we get around them with the second equation
    NSString *max;
    if ([split count] > 1 && [[split objectAtIndex:1] intValue] > 0)
        max = [split objectAtIndex:1];
    else
        max = @"18";
    [self setMaxLabelText:max];

    self.themeCommand = [NSString stringWithFormat:@"etheme %@", [split objectAtIndex:0]];
    self.staticMapCommand = [NSString stringWithFormat:@"emap %@", [source objectAtIndex:index]];

    if (scIndex != 3)
        self.missionCommand = @"";
    else
        self.missionCommand = [NSString stringWithFormat:@"escript Missions/Maps/%@/map.lua",[source objectAtIndex:index]];
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        NSArray *source = [self.dataSourceArray objectAtIndex:scIndex];
        if (isRandomness()) {
            // just change the theme, don't update preview
            self.themeCommand = [NSString stringWithFormat:@"etheme %@", [source objectAtIndex:newRow]];
        } else {
            NSString *fileImage = [NSString stringWithFormat:@"%@/%@/preview.png",
                                   (scIndex == 1) ? MAPS_DIRECTORY() : MISSIONS_DIRECTORY(),[source objectAtIndex:newRow]];
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
#pragma mark slider & segmentedControl & button
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
                labelText = NSLocalizedString(@"Large",@"");
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
                labelText = NSLocalizedString(@"Small",@"");
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

    self.slider.textValue = labelText;
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
    [[AudioManagerController mainManager] playClickSound];
}

// perform actions based on the activated section, then call updatePreview to visually update the selection
// and if necessary update the table with a slide animation
-(IBAction) segmentedControlChanged:(id) sender {
    NSString *mapgen, *staticmap, *mission;
    NSInteger newPage = self.segmentedControl.selectedSegmentIndex;

    [[AudioManagerController mainManager] playSelectSound];
    switch (newPage) {
        case 0: // Random
            mapgen = @"e$mapgen 0";
            staticmap = @"";
            mission = @"";
            [self sliderChanged:nil];
            self.slider.enabled = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fillsections" object:nil];
            break;

        case 1: // Map
            mapgen = @"e$mapgen 0";
            // dummy values, these are set by -updatePreview -> -didSelectRowAtIndexPath -> -setDetailsForStaticMap
            staticmap = @"map Bamboo";
            mission = @"";
            self.slider.enabled = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fillsections" object:nil];
            break;

        case 2: // Maze
            mapgen = @"e$mapgen 1";
            staticmap = @"";
            mission = @"";
            [self sliderChanged:nil];
            self.slider.enabled = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fillsections" object:nil];
            break;

        case 3: // Mission
            mapgen = @"e$mapgen 0";
            // dummy values, these are set by -updatePreview -> -didSelectRowAtIndexPath -> -setDetailsForStaticMap
            staticmap = @"map Bamboo";
            mission = @"";
            self.slider.enabled = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"emptysections" object:nil];
            break;

        default:
            mapgen = nil;
            staticmap = nil;
            mission = nil;
            break;
    }
    self.mapGenCommand = mapgen;
    self.staticMapCommand = staticmap;
    self.missionCommand = mission;

    [self.tableView reloadData];
    [self updatePreview];
    oldPage = newPage;
}

#pragma mark -
#pragma mark view management
-(NSArray *) dataSourceArray {
    if (dataSourceArray == nil) {
        NSString *model = [HWUtils modelType];

        // only folders containing icon.png are a valid theme
        NSArray *themeArrayFull = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:THEMES_DIRECTORY() error:NULL];
        NSMutableArray *themeArray = [[NSMutableArray alloc] init];
        for (NSString *themeName in themeArrayFull) {
            NSString *checkPath = [[NSString alloc] initWithFormat:@"%@/%@/icon.png",THEMES_DIRECTORY(),themeName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:checkPath])
                [themeArray addObject:themeName];
            [checkPath release];
        }

        // remove images that are too big for certain devices without loading the whole image
        NSArray *mapArrayFull = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:MAPS_DIRECTORY() error:NULL];
        NSMutableArray *mapArray = [[NSMutableArray alloc] init];
        for (NSString *str in mapArrayFull) {
            CGSize imgSize = [UIImage imageSizeFromMetadataOf:[MAPS_DIRECTORY() stringByAppendingFormat:@"%@/map.png",str]];
            if (IS_NOT_POWERFUL(model) && imgSize.height > 1024.0f)
                continue;
            if (IS_NOT_VERY_POWERFUL(model) && imgSize.height > 1280.0f)
                continue;
            [mapArray addObject:str];
        }

        NSArray *missionArrayFull = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:MISSIONS_DIRECTORY() error:NULL];
        NSMutableArray *missionArray = [[NSMutableArray alloc] init];
        for (NSString *str in missionArrayFull) {
            CGSize imgSize = [UIImage imageSizeFromMetadataOf:[MISSIONS_DIRECTORY() stringByAppendingFormat:@"%@/map.png",str]];
            if (IS_NOT_POWERFUL(model) && imgSize.height > 1024.0f)
                continue;
            if (IS_NOT_VERY_POWERFUL(model) && imgSize.height > 1280.0f)
                continue;
            [missionArray addObject:str];
        }
        NSArray *array = [[NSArray alloc] initWithObjects:themeArray,mapArray,themeArray,missionArray,nil];
        [missionArray release];
        [themeArray release];
        [mapArray release];

        self.dataSourceArray = array;
        [array release];
    }
    return dataSourceArray;
}

-(void) viewDidLoad {
    [super viewDidLoad];

    // initialize some "default" values
    self.slider.value = 0.05f;
    self.slider.enabled = NO;
    self.oldValue = 5;
    self.busy = NO;
    self.oldPage = self.segmentedControl.selectedSegmentIndex;

    self.templateFilterCommand = @"e$template_filter 0";
    self.mazeSizeCommand = @"e$maze_size 0";
    self.mapGenCommand = @"e$mapgen 0";
    self.staticMapCommand = @"";
    self.missionCommand = @"";

    if (IS_IPAD()) {
        [self.tableView setBackgroundColorForAnyTable:[UIColor darkBlueColorTransparent]];
        self.tableView.layer.borderColor = [[UIColor darkYellowColor] CGColor];
        self.tableView.layer.borderWidth = 2.7f;
        self.tableView.layer.cornerRadius = 8;
        self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);

        UILabel *backLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 14, 300, 190) andTitle:nil withBorderWidth:2.3f];
        backLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.view insertSubview:backLabel belowSubview:self.segmentedControl];
        [backLabel release];
    }
    self.tableView.separatorColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL) animated {
    [self updatePreview];
    [super viewDidAppear:animated];
}

-(void) viewDidUnload {
    self.previewButton = nil;
    self.seedCommand = nil;
    self.templateFilterCommand = nil;
    self.mapGenCommand = nil;
    self.mazeSizeCommand = nil;
    self.themeCommand = nil;
    self.staticMapCommand = nil;
    self.missionCommand = nil;

    self.tableView = nil;
    self.maxLabel = nil;
    self.segmentedControl = nil;
    self.slider = nil;

    self.lastIndexPath = nil;
    self.dataSourceArray = nil;

    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) didReceiveMemoryWarning {
    self.dataSourceArray = nil;
    [super didReceiveMemoryWarning];

    if (self.view.superview == nil) {
        self.previewButton = nil;
        self.tableView = nil;
        self.maxLabel = nil;
        self.slider = nil;
    }

    MSG_MEMCLEAN();
}

-(void) dealloc {
    releaseAndNil(seedCommand);
    releaseAndNil(templateFilterCommand);
    releaseAndNil(mapGenCommand);
    releaseAndNil(mazeSizeCommand);
    releaseAndNil(themeCommand);
    releaseAndNil(staticMapCommand);
    releaseAndNil(missionCommand);

    releaseAndNil(previewButton);
    releaseAndNil(tableView);
    releaseAndNil(maxLabel);
    releaseAndNil(segmentedControl);
    releaseAndNil(slider);

    releaseAndNil(lastIndexPath);
    releaseAndNil(dataSourceArray);

    [super dealloc];
}

@end
