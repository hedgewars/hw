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

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View management
-(void) viewDidLoad
{
    [super viewDidLoad];
    
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
}

-(void) viewWillAppear:(BOOL)animated {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:arc4random_uniform((int)[self.listOfMissionIDs count]) inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
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

#pragma mark - Missions dictionaries methods

- (NSDictionary *)newLocalizedMissionsDictionary
{
    NSString *languageID = [HWUtils languageID];
    
    NSString *missionsDescLocation = [[NSString alloc] initWithFormat:@"%@/missions_en.txt",LOCALE_DIRECTORY()];
    NSString *localizedMissionsDescLocation = [[NSString alloc] initWithFormat:@"%@/missions_%@.txt", LOCALE_DIRECTORY(), languageID];
    
    if (![languageID isEqualToString:@"en"] && [[NSFileManager defaultManager] fileExistsAtPath:localizedMissionsDescLocation])
    {
        NSDictionary *missionsDict = [self newMissionsDictionaryFromMissionsFile:missionsDescLocation];
        NSDictionary *localizedMissionsDict = [self newMissionsDictionaryFromMissionsFile:localizedMissionsDescLocation];
        
        [missionsDescLocation release];
        [localizedMissionsDescLocation release];
        
        NSMutableDictionary *tempMissionsDict = [[NSMutableDictionary alloc] init];
        
        for (NSString *key in [missionsDict allKeys])
        {
            if ([localizedMissionsDict objectForKey:key])
            {
                [tempMissionsDict setObject:[localizedMissionsDict objectForKey:key] forKey:key];
            }
            else
            {
                [tempMissionsDict setObject:[missionsDict objectForKey:key] forKey:key];
            }
        }
        
        [missionsDict release];
        [localizedMissionsDict release];
        
        return tempMissionsDict;
    }
    else
    {
        NSDictionary *missionsDict = [self newMissionsDictionaryFromMissionsFile:missionsDescLocation];
        
        [missionsDescLocation release];
        [localizedMissionsDescLocation release];
        
        return missionsDict;
    }
}

- (NSDictionary *)newMissionsDictionaryFromMissionsFile:(NSString *)filePath
{
    NSMutableDictionary *missionsDict = [[NSMutableDictionary alloc] init];
    
    NSString *missionsFileContents = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    NSArray *missionsLines = [missionsFileContents componentsSeparatedByString:@"\n"];
    [missionsFileContents release];
    
    for (NSString *line in missionsLines)
    {
        if ([line length] > 0)
        {
            NSUInteger firstDotLocation = [line rangeOfString:@"."].location;
            
            NSString *missionID = [line substringToIndex:firstDotLocation];
            
            NSString *missionFullPath = [NSString stringWithFormat:@"%@%@.lua", TRAININGS_DIRECTORY(), missionID];
            if (![[NSFileManager defaultManager] fileExistsAtPath:missionFullPath])
            {
                continue;
            }
            
            NSString *nameOrDesc = [line substringFromIndex:firstDotLocation+1];
            
            NSString *missionParsedName = ([nameOrDesc hasPrefix:@"name="]) ? [nameOrDesc stringByReplacingOccurrencesOfString:@"name=" withString:@""] : nil;
            NSString *missionParsedDesc = ([nameOrDesc hasPrefix:@"desc="]) ? [nameOrDesc stringByReplacingOccurrencesOfString:@"desc=" withString:@""] : nil;
            
            if (![missionsDict objectForKey:missionID])
            {
                NSMutableDictionary *missionDict = [[NSMutableDictionary alloc] init];
                [missionsDict setObject:missionDict forKey:missionID];
                [missionDict release];
            }
            
            NSMutableDictionary *missionDict = [missionsDict objectForKey:missionID];
            
            if (missionParsedName)
            {
                [missionDict setObject:missionParsedName forKey:@"name"];
            }
            
            if (missionParsedDesc)
            {
                missionParsedDesc = [missionParsedDesc stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                [missionDict setObject:missionParsedDesc forKey:@"desc"];
            }
            
            [missionsDict setObject:missionDict forKey:missionID];
        }
    }
    
    return missionsDict;
}

#pragma mark -
#pragma mark override setters/getters for better memory handling

-(NSArray *)listOfMissionIDs
{
    if (!_listOfMissionIDs)
    {
        NSArray *sortedKeys = [[self.dictOfMissions allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        _listOfMissionIDs = [[NSArray alloc] initWithArray:sortedKeys];
    }
    
    return _listOfMissionIDs;
}

- (NSDictionary *)dictOfMissions
{
    if (!_dictOfMissions)
    {
        _dictOfMissions = [self newLocalizedMissionsDictionary];
    }
    
    return _dictOfMissions;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfMissionIDs count];
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
    
    NSString *missionID = [self.listOfMissionIDs objectAtIndex:row];
    cell.textLabel.text = self.dictOfMissions[missionID][@"name"];
    
    cell.textLabel.textColor = [UIColor lightYellowColor];
    //cell.textLabel.font = [UIFont fontWithName:@"Bradley Hand Bold" size:[UIFont labelFontSize]];
    cell.textLabel.textAlignment = (IS_IPAD()) ? UITextAlignmentCenter : UITextAlignmentLeft;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.text = (IS_IPAD()) ? nil : self.dictOfMissions[missionID][@"desc"];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.numberOfLines = ([cell.detailTextLabel.text length] % 40);
    cell.detailTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:(85.0/255.0) green:(15.0/255.0) blue:(106.0/255.0) alpha:1.0];
    bgColorView.layer.masksToBounds = YES;
    cell.selectedBackgroundView = bgColorView;
    [bgColorView release];
    
    cell.backgroundColor = [UIColor blackColorTransparent];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];

    self.missionName = [self.listOfMissionIDs objectAtIndex:row];
    NSString *size = IS_IPAD() ? @"@2x" : @"";
    NSString *filePath = [[NSString alloc] initWithFormat:@"%@/Missions/Training/%@%@.png",GRAPHICS_DIRECTORY(),self.missionName,size];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:filePath];
    [filePath release];
    [self.previewImage setImage:img];
    [img release];

    self.descriptionLabel.text = self.dictOfMissions[self.missionName][@"desc"];
}

#pragma mark -
#pragma mark Memory management

-(void) didReceiveMemoryWarning
{
    self.missionName = nil;
    self.listOfMissionIDs = nil;
    self.dictOfMissions = nil;
    // if you nil this one it won't get updated anymore
    //self.previewImage = nil;
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload
{
    self.listOfMissionIDs = nil;
    self.dictOfMissions = nil;
    self.previewImage = nil;
    self.tableView = nil;
    self.descriptionLabel = nil;
    self.missionName = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}


-(void) dealloc
{
    releaseAndNil(_listOfMissionIDs);
    releaseAndNil(_dictOfMissions);
    releaseAndNil(_previewImage);
    releaseAndNil(_tableView);
    releaseAndNil(_descriptionLabel);
    releaseAndNil(_missionName);
    [super dealloc];
}


@end
