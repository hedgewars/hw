/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * File created on 03/10/2011.
 */

#import "MissionTrainingViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GameInterfaceBridge.h"

@implementation MissionTrainingViewController
@synthesize listOfMissions, previewImage, tableView, descriptionLabel, missionName;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void) viewDidLoad {
    NSString *imgName = (IS_IPAD()) ? @"mediumBackground~ipad.png" : @"smallerBackground~iphone.png";
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgName];
    self.view.backgroundColor = [UIColor colorWithPatternImage:img];
    [img release];
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TRAININGS_DIRECTORY() error:NULL];
    self.listOfMissions = array;
    self.previewImage.layer.borderColor = [[UIColor darkYellowColor] CGColor];
    self.previewImage.layer.borderWidth = 3.8f;
    self.previewImage.layer.cornerRadius = 14;

    UIView *backView = [[UIView alloc] initWithFrame:self.tableView.frame];
    backView.backgroundColor = [UIColor darkBlueColorTransparent];
    [self.tableView setBackgroundView:backView];
    [backView release];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.borderColor = [[UIColor darkYellowColor] CGColor];
    self.tableView.layer.borderWidth = 2;
    self.tableView.layer.cornerRadius = 8;

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
        [AudioManagerController playBackSound];
        [[self parentViewController] dismissModalViewControllerAnimated:YES];
    } else {
        GameInterfaceBridge *bridge = [[GameInterfaceBridge alloc] initWithController:self];
        [bridge startMissionGame:self.missionName];
        [bridge release];
    }
}

#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfMissions count];
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellTr";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    cell.textLabel.text = [[[self.listOfMissions objectAtIndex:[indexPath row]] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    cell.textLabel.textColor = [UIColor lightYellowColor];
    //cell.textLabel.font = [UIFont fontWithName:@"Bradley Hand Bold" size:[UIFont labelFontSize]];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor blackColorTransparent];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.missionName = [[self.listOfMissions objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
    NSString *filePath = [[NSString alloc] initWithFormat:@"%@/Missions/Training/%@@2x.png",GRAPHICS_DIRECTORY(),self.missionName];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:filePath];
    [filePath release];
    [self.previewImage setImage:img];
    [img release];

    self.descriptionLabel.text = nil;
    NSString *descLocation = [[NSString alloc] initWithFormat:@"%@/missions_en.txt",LOCALE_DIRECTORY()];
    NSString *descComplete = [[NSString alloc] initWithContentsOfFile:descLocation encoding:NSUTF8StringEncoding error:NULL];
    [descLocation release];
    NSArray *descArray =  [descComplete componentsSeparatedByString:@"\n"];
    [descComplete release];
    for (NSString *str in descArray) {
        if ([str hasPrefix:missionName]) {
            NSArray *descriptionText = [str componentsSeparatedByString:@"\""];
            self.descriptionLabel.text = [descriptionText objectAtIndex:1];
        }
    }
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    previewImage = nil;
    missionName = nil;
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.listOfMissions = nil;
    self.previewImage = nil;
    self.tableView = nil;
    self.descriptionLabel = nil;
    self.missionName = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc {
    releaseAndNil(listOfMissions);
    releaseAndNil(previewImage);
    releaseAndNil(tableView);
    releaseAndNil(descriptionLabel);
    releaseAndNil(missionName);
    [super dealloc];
}


@end
