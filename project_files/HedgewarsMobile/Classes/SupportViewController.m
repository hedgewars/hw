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


#import "SupportViewController.h"
#import "Appirater.h"

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
                      NSLocalizedString(@"Follow us on Twitter",@""),
                      NSLocalizedString(@"Visit our website",@""),
                      NSLocalizedString(@"Chat with the devs in IRC",@""),
                      nil];
    self.waysToSupport = array;
    [array release];

    self.navigationItem.title = @"♥";
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
    NSString *imgName = @"";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    NSString *rowString = [self.waysToSupport objectAtIndex:(row + section)];
    cell.textLabel.text = rowString;

    if (section == 0) {
        imgName = @"star";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.imageView.image = nil;
    } else {
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        switch (row) {
            case 0:
                imgName = @"fb";
                break;
            case 1:
                imgName = @"tw";
                break;
            case 2:
                imgName = @"hedgehog";
                break;
            case 3:
                imgName = @"irc";
                break;
            default:
                DLog(@"No way");
                break;
        }
        cell.accessoryView = nil;
    }

    NSString *imgString = [[NSString alloc] initWithFormat:@"%@/%@.png",[[NSBundle mainBundle] resourcePath],imgName];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgString];
    [imgString release];
    cell.imageView.image = img;
    if (section == 0) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        cell.accessoryView = imgView;
        [imgView release];
    }
    [img release];

    return cell;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0)
    {
        [Appirater rateApp];
    }
    else
    {
        NSString *urlString = nil;
        switch ([indexPath row])
        {
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
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger) section {
    if (section == 1) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 240)];
        footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIImage *img = [[UIImage alloc] initWithContentsOfFile:@"surprise.png"];
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        [img release];
        imgView.center = CGPointMake(self.tableView.frame.size.width/2, 120);
        imgView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [footer addSubview:imgView];
        [imgView release];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 20)];
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        label.textAlignment = UITextAlignmentCenter;
        label.text = NSLocalizedString(@" ♥ THANK YOU ♥ ", nil);
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
    return (section == 1) ? 265 : 20;
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
    releaseAndNil(waysToSupport);
    [super dealloc];
}

@end
