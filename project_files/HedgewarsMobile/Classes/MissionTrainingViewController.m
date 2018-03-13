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

#define TRAINING_MISSION_TYPE @"Training"
#define CHALLENGE_MISSION_TYPE @"Challenge"
#define SCENARIO_MISSION_TYPE @"Scenario"

@implementation MissionTrainingViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View management
- (void)viewDidLoad
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

- (void)viewWillAppear:(BOOL)animated {
    NSInteger randomSection = arc4random_uniform((int)[self.missionsTypes count]);
    NSString *type = self.missionsTypes[randomSection];
    NSArray *listOfIDs = [self listOfMissionsIDsForType:type];
    NSInteger randomRow = arc4random_uniform((int)[listOfIDs count]);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:randomRow inSection:randomSection];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    [super viewWillAppear:animated];
}

- (IBAction)buttonPressed:(id)sender {
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

- (NSDictionary *)newLocalizedMissionsDictionaryForType: (NSString *)type
{
    NSString *languageID = [HWUtils languageID];
    
    NSString *missionsDescLocation = [[NSString alloc] initWithFormat:@"%@/missions_en.txt", LOCALE_DIRECTORY()];
    NSString *localizedMissionsDescLocation = [[NSString alloc] initWithFormat:@"%@/missions_%@.txt", LOCALE_DIRECTORY(), languageID];
    
    if (![languageID isEqualToString:@"en"] && [[NSFileManager defaultManager] fileExistsAtPath:localizedMissionsDescLocation])
    {
        NSDictionary *missionsDict = [self newMissionsDictionaryForType:type fromMissionsFile:missionsDescLocation];
        NSDictionary *localizedMissionsDict = [self newMissionsDictionaryForType:type fromMissionsFile:localizedMissionsDescLocation];
        
        
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
        
        
        return tempMissionsDict;
    }
    else
    {
        NSDictionary *missionsDict = [self newMissionsDictionaryForType:type fromMissionsFile:missionsDescLocation];
        
        
        return missionsDict;
    }
}

- (NSDictionary *)newMissionsDictionaryForType:(NSString *)type fromMissionsFile:(NSString *)filePath
{
    NSMutableDictionary *missionsDict = [[NSMutableDictionary alloc] init];
    
    NSString *missionsFileContents = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    NSArray *missionsLines = [missionsFileContents componentsSeparatedByString:@"\n"];
    
    NSString *directory = [self missionsDirectoryForType:type];
    for (NSString *line in missionsLines)
    {
        if ([line length] > 0)
        {
            NSUInteger firstDotLocation = [line rangeOfString:@"."].location;
            
            NSString *missionID = [line substringToIndex:firstDotLocation];
            
            NSString *missionFullPath = [NSString stringWithFormat:@"%@%@.lua", directory, missionID];
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

- (NSArray *)missionsTypes
{
    if (!_missionsTypes)
    {
        _missionsTypes = @[ TRAINING_MISSION_TYPE, CHALLENGE_MISSION_TYPE, SCENARIO_MISSION_TYPE ];
    }
    
    return _missionsTypes;
}

- (NSDictionary *)dictOfAllMissions
{
    if (!_dictOfAllMissions)
    {
        NSArray *types = [self missionsTypes];
        _dictOfAllMissions = @{ types[0] : self.dictOfTraining,
                                types[1] : self.dictOfChallenge,
                                types[2] : self.dictOfScenario };
    }
    
    return _dictOfAllMissions;
}

- (NSArray *)listOfTrainingIDs
{
    if (!_listOfTrainingIDs)
    {
        _listOfTrainingIDs = [[self.dictOfTraining allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    
    return _listOfTrainingIDs;
}

- (NSDictionary *)dictOfTraining
{
    if (!_dictOfTraining)
    {
        _dictOfTraining = [self newLocalizedMissionsDictionaryForType:TRAINING_MISSION_TYPE];
    }
    
    return _dictOfTraining;
}

- (NSArray *)listOfChallengeIDs
{
    if (!_listOfChallengeIDs)
    {
        _listOfChallengeIDs = [[self.dictOfChallenge allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    
    return _listOfChallengeIDs;
}

- (NSDictionary *)dictOfChallenge
{
    if (!_dictOfChallenge)
    {
        _dictOfChallenge = [self newLocalizedMissionsDictionaryForType:CHALLENGE_MISSION_TYPE];
    }
    
    return _dictOfChallenge;
}

- (NSArray *)listOfScenarioIDs
{
    if (!_listOfScenarioIDs)
    {
        _listOfScenarioIDs = [[self.dictOfScenario allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }

    return _listOfScenarioIDs;
}

- (NSDictionary *)dictOfScenario
{
    if (!_dictOfScenario)
    {
        _dictOfScenario = [self newLocalizedMissionsDictionaryForType:SCENARIO_MISSION_TYPE];
    }

    return _dictOfScenario;
}

#pragma mark -
#pragma mark Missions types

- (NSString *)missionsDirectoryForType:(NSString *)type
{
    if ([type isEqualToString:TRAINING_MISSION_TYPE]) {
        return TRAININGS_DIRECTORY();
    } else if ([type isEqualToString:CHALLENGE_MISSION_TYPE]) {
        return CHALLENGE_DIRECTORY();
    } else if ([type isEqualToString:SCENARIO_MISSION_TYPE]) {
        return SCENARIO_DIRECTORY();
    }
    return nil;
}

- (NSArray *)listOfMissionsIDsForType:(NSString *)type
{
    if ([type isEqualToString:TRAINING_MISSION_TYPE]) {
        return self.listOfTrainingIDs;
    } else if ([type isEqualToString:CHALLENGE_MISSION_TYPE]) {
        return self.listOfChallengeIDs;
    } else if ([type isEqualToString:SCENARIO_MISSION_TYPE]) {
        return self.listOfScenarioIDs;
    }
    return nil;
}

- (NSDictionary *)dictOfMissionsForType:(NSString *)type
{
    if ([type isEqualToString:TRAINING_MISSION_TYPE]) {
        return self.dictOfTraining;
    } else if ([type isEqualToString:CHALLENGE_MISSION_TYPE]) {
        return self.dictOfChallenge;
    } else if ([type isEqualToString:SCENARIO_MISSION_TYPE]) {
        return self.dictOfScenario;
    }
    return nil;
}

#pragma mark -
#pragma mark Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.missionsTypes count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *type = self.missionsTypes[section];
    NSArray *listOfIDs = [self listOfMissionsIDsForType:type];
    return [listOfIDs count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (IS_IPAD()) ? self.tableView.rowHeight : 80;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellTr";
    NSInteger row = [indexPath row];

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:(IS_IPAD()) ? UITableViewCellStyleDefault : UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier];
    
    NSInteger section = [indexPath section];
    NSString *type = self.missionsTypes[section];
    NSArray *listOfIDs = [self listOfMissionsIDsForType:type];
    NSDictionary *dict = [self dictOfMissionsForType:type];
    
    NSString *missionID = [listOfIDs objectAtIndex:row];
    cell.textLabel.text = dict[missionID][@"name"];
    
    cell.textLabel.textColor = [UIColor lightYellowColor];
    //cell.textLabel.font = [UIFont fontWithName:@"Bradley Hand Bold" size:[UIFont labelFontSize]];
    cell.textLabel.textAlignment = (IS_IPAD()) ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.text = (IS_IPAD()) ? nil : dict[missionID][@"desc"];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.numberOfLines = ([cell.detailTextLabel.text length] % 40);
    cell.detailTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:(85.0/255.0) green:(15.0/255.0) blue:(106.0/255.0) alpha:1.0];
    bgColorView.layer.masksToBounds = YES;
    cell.selectedBackgroundView = bgColorView;
    
    cell.backgroundColor = [UIColor blackColorTransparent];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = [indexPath section];
    NSString *type = self.missionsTypes[section];
    NSArray *listOfIDs = [self listOfMissionsIDsForType:type];
    
    NSInteger row = [indexPath row];
    self.missionName = [listOfIDs objectAtIndex:row];
    NSString *size = IS_IPAD() ? @"@2x" : @"";
    NSString *filePath = [[NSString alloc] initWithFormat:@"%@/Missions/%@/%@%@.png",GRAPHICS_DIRECTORY(), type, self.missionName, size];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:filePath];
    [self.previewImage setImage:img];

    NSDictionary *dict = [self dictOfMissionsForType:type];
    self.descriptionLabel.text = dict[self.missionName][@"desc"];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    self.listOfTrainingIDs = nil;
    self.dictOfTraining = nil;
    self.dictOfAllMissions = nil;
    self.missionsTypes = nil;
    // if you nil this one it won't get updated anymore
    //self.previewImage = nil;
    [super didReceiveMemoryWarning];
}

@end
