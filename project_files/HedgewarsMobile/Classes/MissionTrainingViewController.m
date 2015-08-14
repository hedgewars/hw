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


#import "MissionTrainingViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GameInterfaceBridge.h"


@implementation MissionTrainingViewController
@synthesize listOfMissions, listOfDescriptions, previewImage, tableView, descriptionLabel, missionName;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View management
-(void) viewDidLoad {
    self.previewImage.layer.borderColor = [[UIColor darkYellowColor] CGColor];
    self.previewImage.layer.borderWidth = 3.8f;
    self.previewImage.layer.cornerRadius = 14;

    if (IS_IPAD()) {
        [self.tableView setBackgroundColorForAnyTable:[UIColor darkBlueColorTransparent]];
        self.tableView.layer.borderColor = [[UIColor darkYellowColor] CGColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        [self.tableView setBackgroundColorForAnyTable:[UIColor blackColorTransparent]];
        self.tableView.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    self.tableView.layer.borderWidth = 2.4f;
    self.tableView.layer.cornerRadius = 8;
    self.tableView.separatorColor = [UIColor whiteColor];

    self.descriptionLabel.textColor = [UIColor lightYellowColor];
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:random()%[self.listOfMissions count] inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    [super viewWillAppear:animated];
}

-(IBAction) buttonPressed:(id) sender {
    UIButton *button = (UIButton *)sender;

    if (button.tag == 0) {
        [[AudioManagerController mainManager] playBackSound];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [GameInterfaceBridge registerCallingController:self];
        [GameInterfaceBridge startMissionGame:self.missionName];
    }
}

#pragma mark -
#pragma mark override setters/getters for better memory handling
-(NSArray *)listOfMissions {
    if (listOfMissions == nil)
        self.listOfMissions = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TRAININGS_DIRECTORY() error:NULL];
    return listOfMissions;
}

-(NSArray *)listOfDescriptions {
    if (listOfDescriptions == nil) {
        NSString *descLocation = [[NSString alloc] initWithFormat:@"%@/missions_en.txt",LOCALE_DIRECTORY()];
        NSString *descComplete = [[NSString alloc] initWithContentsOfFile:descLocation encoding:NSUTF8StringEncoding error:NULL];
        [descLocation release];
        NSArray *descArray = [descComplete componentsSeparatedByString:@"\n"];
        NSMutableArray *filteredArray = [[NSMutableArray alloc] initWithCapacity:[descArray count]/3];
        [descComplete release];
        // sanity check to avoid having missions and descriptions conflicts
        for (NSUInteger i = 0; i < [self.listOfMissions count]; i++) {
            NSString *desc = [[self.listOfMissions objectAtIndex:i] stringByDeletingPathExtension];
            for (NSString *str in descArray)
                if ([str hasPrefix:desc] && [str hasSuffix:@"\""]) {
                    NSArray *descriptionText = [str componentsSeparatedByString:@"\""];
                    [filteredArray insertObject:[descriptionText objectAtIndex:1] atIndex:i];
                    break;
                }
        }
        self.listOfDescriptions = filteredArray;
        [filteredArray release];
    }
    return listOfDescriptions;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfMissions count];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (IS_IPAD()) ? self.tableView.rowHeight : 80;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellTr";
    NSInteger row = [indexPath row];

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:(IS_IPAD()) ? UITableViewCellStyleDefault : UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];

    cell.textLabel.text = [[[self.listOfMissions objectAtIndex:row] stringByDeletingPathExtension]
                           stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    cell.textLabel.textColor = [UIColor lightYellowColor];
    //cell.textLabel.font = [UIFont fontWithName:@"Bradley Hand Bold" size:[UIFont labelFontSize]];
    cell.textLabel.textAlignment = (IS_IPAD()) ? UITextAlignmentCenter : UITextAlignmentLeft;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.text = (IS_IPAD()) ? nil : [self.listOfDescriptions objectAtIndex:row];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.numberOfLines = ([cell.detailTextLabel.text length] % 40);
    cell.detailTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    cell.backgroundColor = [UIColor blackColorTransparent];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];

    self.missionName = [[self.listOfMissions objectAtIndex:row] stringByDeletingPathExtension];
    NSString *size = IS_IPAD() ? @"@2x" : @"";
    NSString *filePath = [[NSString alloc] initWithFormat:@"%@/Missions/Training/%@%@.png",GRAPHICS_DIRECTORY(),self.missionName,size];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:filePath];
    [filePath release];
    [self.previewImage setImage:img];
    [img release];

    self.descriptionLabel.text = [self.listOfDescriptions objectAtIndex:row];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    self.previewImage = nil;
    self.missionName = nil;
    self.listOfMissions = nil;
    self.listOfDescriptions = nil;
    // if you nil this one it won't get updated anymore
    //self.previewImage = nil;
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.listOfMissions = nil;
    self.listOfDescriptions = nil;
    self.previewImage = nil;
    self.tableView = nil;
    self.descriptionLabel = nil;
    self.missionName = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc {
    releaseAndNil(listOfMissions);
    releaseAndNil(listOfDescriptions);
    releaseAndNil(previewImage);
    releaseAndNil(tableView);
    releaseAndNil(descriptionLabel);
    releaseAndNil(missionName);
    [super dealloc];
}


@end
