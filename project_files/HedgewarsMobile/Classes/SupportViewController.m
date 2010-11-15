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
 * File created on 19/09/2010.
 */


#import "SupportViewController.h"
#import "CommodityFunctions.h"

@implementation SupportViewController
@synthesize waysToSupport;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    NSArray *array = [[NSArray alloc] initWithObjects:
                      NSLocalizedString(@"Leave a positive review on iTunes!",@""),
                      NSLocalizedString(@"Join us on Facebook",@""),
                      NSLocalizedString(@"Follow on Twitter",@""),
                      NSLocalizedString(@"Visit website",@""),
                      NSLocalizedString(@"Chat with us in IRC",@""),
                      nil];
    self.waysToSupport = array;
    [array release];

    self.tableView.rowHeight = 50;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 1;
    else
        return [self.waysToSupport count] - 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    NSString *rowString = [self.waysToSupport objectAtIndex:(row + section)];
    cell.textLabel.text = rowString;

    if (section == 0) {
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.imageView.image = nil;
    } else {
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        NSString *imgString = nil;
        switch (row) {
            case 0:
                imgString = @"fb.png";
                break;
            case 1:
                imgString = @"tw.png";
                break;
            case 2:
                imgString = @"Icon-Small.png";
                break;
            case 3:
                imgString = @"irc.png";
                break;
            default:
                DLog(@"No way");
                break;
        }
        
        UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgString];
        cell.imageView.image = img;
        [img release];
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *urlString = nil;
    if ([indexPath section] == 0)
        urlString = @"http://itunes.apple.com/us/app/hedgewars/id391234866?affC=QQABAAAAHgAFasEiWjVwUGZOc3k1VGctQkRJazlacXhUclpBTVpiU2xteVdfUQ%3D%3D#&mt=8";
    else
        switch ([indexPath row]) {
            case 0:
                urlString = @"http://www.facebook.com/Hedgewars";
                break;
            case 1:
                urlString = @"http://twitter.com/hedgewars";
                break;
            case 2:
                urlString = @"http://www.hedgewars.org";
                break;
            case 3:
                urlString = @"http://webchat.freenode.net/?channels=hedgewars";
                break;
            default:
                DLog(@"No way");
                break;
        }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger) section {
    if (section == 1) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 240)];
        UIImage *img = [[UIImage alloc] initWithContentsOfFile:@"surprise.png"];
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        [img release];
        imgView.center = CGPointMake(self.tableView.frame.size.width/2, 120);
        [footer addSubview:imgView];
        [imgView release];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 20)];
        label.textAlignment = UITextAlignmentCenter;
        label.text = @" ♥ THANK YOU ♥ ";
        label.backgroundColor = [UIColor clearColor];
        label.center = CGPointMake(self.tableView.frame.size.width/2, 250);
        [footer addSubview:label];
        [label release];
        
        return [footer autorelease];
    } else
        return nil;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // image height + label height
    return 265;
}

#pragma mark -
#pragma mark Memory management
-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.waysToSupport = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [self.waysToSupport release];
    [super dealloc];
}

@end
