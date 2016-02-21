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

#import "CampaignsViewController.h"

@interface CampaignsViewController ()
@property (nonatomic, retain) NSArray *campaigns;
@end

@implementation CampaignsViewController

#pragma mark - Lazy instantiation

- (NSArray *)campaigns {
    if (!_campaigns) {
        _campaigns = [self listOfCampaigns];
    }
    return _campaigns;
}

- (NSArray *)listOfCampaigns {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:CAMPAIGNS_DIRECTORY() error:nil];
    
    NSMutableArray *tempCampaigns = [[NSMutableArray alloc] init];
    for (NSString *item in contents) {
        NSString *fullItemPath = [CAMPAIGNS_DIRECTORY() stringByAppendingString:item];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullItemPath isDirectory:&isDirectory] && isDirectory) {
            [tempCampaigns addObject:item];
        }
    }
    
    NSArray *campaigns = [tempCampaigns copy];
    [tempCampaigns release];
    return campaigns;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = doneButton;
    [doneButton release];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"campaignCell"];
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
    return [self.campaigns count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"campaignCell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.campaigns[indexPath.row];
    
    return cell;
}

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

#pragma mark - Dealloc

- (void)dealloc {
    [_campaigns release];
    [super dealloc];
}

@end
