//
//  SingleTeamViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SingleTeamViewController.h"
#import "HogHatViewController.h"

@implementation SingleTeamViewController
@synthesize teamDictionary, hatArray, secondaryItems;


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
   
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:
                             NSLocalizedString(@"Color",@""),
                             NSLocalizedString(@"Grave",@""),
                             NSLocalizedString(@"Voice",@""),
                             NSLocalizedString(@"Fort",@""),
                             NSLocalizedString(@"Flag",@""),
                             NSLocalizedString(@"Level",@""),nil];
    self.secondaryItems = array;
    [array release];
    
    // load data about the team and extract info
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/Teams/%@.plist",[paths objectAtIndex:0],self.title];
    NSMutableDictionary *teamDict = [[NSMutableDictionary alloc] initWithContentsOfFile:teamFile];
    [teamFile release];
    self.teamDictionary = teamDict;
    [teamDict release];

    // listen if any childController modifies the plist and write it if needed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWriteNeeded) name:@"setWriteNeedTeams" object:nil];
    isWriteNeeded = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // grab the name of the team
    self.title = [self.teamDictionary objectForKey:@"teamname"];
    
    // load the images of the hat for aach hog
    NSArray *hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[hogArray count]];
    for (NSDictionary *hog in hogArray) {
        NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/Data/Graphics/Hats/%@.png",[[NSBundle mainBundle] resourcePath],[hog objectForKey:@"hat"]];

        UIImage *image = [[UIImage alloc] initWithContentsOfFile: hatFile];
        [hatFile release];
        CGRect firstSpriteArea = CGRectMake(0, 0, 32, 32);
        CGImageRef cgImgage = CGImageCreateWithImageInRect([image CGImage], firstSpriteArea);
        [image release];
        
        UIImage *hatSprite = [[UIImage alloc] initWithCGImage:cgImgage];
        [array addObject:hatSprite];
        CGImageRelease(cgImgage);
        [hatSprite release];
    }
    self.hatArray = array;
    [array release];
    
    [self.tableView reloadData];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

-(void) setWriteNeeded {
    isWriteNeeded = YES;
}

// write to disk the team dictionary
-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (isWriteNeeded) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/Teams/%@.plist",[paths objectAtIndex:0],self.title];
        [self.teamDictionary writeToFile: teamFile atomically:YES];
        [teamFile release];

        isWriteNeeded = NO;
    }
}

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    switch (section) {
        case 0:
            rows = 1;
            break;
        case 1:
            rows = 8;
            break;
        case 2:
            rows = 6;
            break;
        default:
            break;
    }
    return rows;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    NSArray *hogArray;
    NSInteger row = [indexPath row];
    switch ([indexPath section]) {
        case 0:
            cell.textLabel.text = self.title;
            cell.imageView.image = nil;
            break;
        case 1:
            hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];
            cell.textLabel.text = [[hogArray objectAtIndex:row] objectForKey:@"hogname"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self.hatArray objectAtIndex:row];
            break;
        case 2:
            cell.textLabel.text = [self.secondaryItems objectAtIndex:row];
            cell.imageView.image = nil;
            break;
        default:
            break;
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (1 == [indexPath section]) {
        if (nil == hogChildController) {
            hogChildController = [[HogHatViewController alloc] initWithStyle:UITableViewStyleGrouped];
        }
        
        // cache the dictionary file of the team, so that other controllers can modify it
        hogChildController.teamDictionary = self.teamDictionary;
        hogChildController.selectedHog = [indexPath row];

        [self.navigationController pushViewController:hogChildController animated:YES];
    }
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    self.hatArray = nil;
    self.secondaryItems = nil;
    self.teamDictionary = nil;
    [super viewDidUnload];
}


-(void) dealloc {
    [secondaryItems release];
    [hatArray release];
    [teamDictionary release];
    [super dealloc];
}


@end

