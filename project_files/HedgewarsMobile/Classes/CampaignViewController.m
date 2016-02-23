/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2015-2016 Anton Malmygin <antonc27@mail.ru>
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

#import "CampaignViewController.h"
#import "IniParser.h"
#import "GameInterfaceBridge.h"

@interface CampaignViewController ()
@property (nonatomic, retain) NSArray *campaignMissions;
@end

@implementation CampaignViewController

#pragma mark - Lazy instantiation

- (NSArray *)campaignMissions {
    if (!_campaignMissions) {
        _campaignMissions = [self newParsedMissionsForCurrentCampaign];
    }
    return _campaignMissions;
}

- (NSArray *)newParsedMissionsForCurrentCampaign {
    NSString *campaignIniPath = [CAMPAIGNS_DIRECTORY() stringByAppendingFormat:@"%@/campaign.ini", self.campaignName];
    
    IniParser *iniParser = [[IniParser alloc] initWithIniFilePath:campaignIniPath];
    NSArray *parsedMissions = [iniParser newParsedSections];
    [iniParser release];
    
    return parsedMissions;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"campaignMissionCell"];
}

- (void)dismiss {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.campaignMissions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"campaignMissionCell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.campaignMissions[indexPath.row][@"Name"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *campaignMissionScript = self.campaignMissions[indexPath.row][@"Script"];
    
    [GameInterfaceBridge registerCallingController:self];
    [GameInterfaceBridge startCampaignMissionGameWithScript:campaignMissionScript forCampaign:self.campaignName];
}

#pragma mark - Dealloc

- (void)dealloc {
    [_campaignName release];
    [_campaignMissions release];
    [super dealloc];
}

@end
