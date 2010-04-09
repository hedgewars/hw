//
//  SingleTeamViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SingleTeamViewController.h"
#import "HogHatViewController.h"
#import "FlagsViewController.h"
#import "FortsViewController.h"
#import "CommodityFunctions.h"

@implementation SingleTeamViewController
@synthesize teamDictionary, hatArray, secondaryItems, secondaryControllers;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
   
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:
                             NSLocalizedString(@"Grave",@""),
                             NSLocalizedString(@"Voice",@""),
                             NSLocalizedString(@"Fort",@""),
                             NSLocalizedString(@"Flag",@""),
                             NSLocalizedString(@"Level",@""),nil];
    self.secondaryItems = array;
    [array release];
    
    // insert controllers here
    NSMutableArray *controllersArray = [[NSMutableArray alloc] initWithCapacity:[secondaryItems count]];
    
    FlagsViewController *flagsViewController = [[FlagsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [controllersArray addObject:flagsViewController];
    [flagsViewController release];
    
    FortsViewController *fortsViewController = [[FortsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [controllersArray addObject:fortsViewController];
    [fortsViewController release];
    
    self.secondaryControllers = controllersArray;
    [controllersArray release];

    // listen if any childController modifies the plist and write it if needed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWriteNeeded) name:@"setWriteNeedTeams" object:nil];
    isWriteNeeded = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // load data about the team and extract info
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.title];
    if (isWriteNeeded) {
        [self.teamDictionary writeToFile:teamFile atomically:YES];
        NSLog(@"writing: %@",teamDictionary);
        isWriteNeeded = NO;
    }
    
	NSMutableDictionary *teamDict = [[NSMutableDictionary alloc] initWithContentsOfFile:teamFile];
    self.teamDictionary = teamDict;
    [teamDict release];
    
	[teamFile release];
        
    // load the images of the hat for aach hog
    NSArray *hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[hogArray count]];
    for (NSDictionary *hog in hogArray) {
        NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@.png",HATS_DIRECTORY(),[hog objectForKey:@"hat"]];

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

-(void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.title];
    if (isWriteNeeded) {
        [self.teamDictionary writeToFile:teamFile atomically:YES];
        NSLog(@"writing: %@",teamDictionary);
        isWriteNeeded = NO;
    }

	[teamFile release];
}
// needed by other classes to warn about a user change
-(void) setWriteNeeded {
    isWriteNeeded = YES;
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    switch (section) {
        case 0: // team name
            rows = 1;
            break;
        case 1: // team members
            rows = MAX_HOGS;
            break;
        case 2: // team details
            rows = [self.secondaryItems count];
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
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 1:
            hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];
            cell.textLabel.text = [[hogArray objectAtIndex:row] objectForKey:@"hogname"];
            cell.imageView.image = [self.hatArray objectAtIndex:row];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            break;
        case 2:
            cell.textLabel.text = [self.secondaryItems objectAtIndex:row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (row) {
                case 3: // flags
                    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png",
                                                                             FLAGS_DIRECTORY(),[teamDictionary objectForKey:@"flag"]]];
                    break;
                default:
                    cell.imageView.image = nil;
                    break;
            }
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
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
    NSInteger row = [indexPath row];
    UITableViewController *nextController;
    if (1 == [indexPath section]) {
        //TODO: hog name pref, causes segfault
    }
    if (2 == [indexPath section]) {
        //TODO: this part should be rewrittend with lazy loading instead of an array of controllers
        nextController = [secondaryControllers objectAtIndex:row%2 ];              //TODO: fix the objectAtIndex
        nextController.title = [secondaryItems objectAtIndex:row];
        [nextController setTeamDictionary:teamDictionary];
    }
    [self.navigationController pushViewController:nextController animated:YES];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (nil == hogChildController) {
        hogChildController = [[HogHatViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    // cache the dictionary file of the team, so that other controllers can modify it
    hogChildController.teamDictionary = self.teamDictionary;
    hogChildController.selectedHog = [indexPath row];
    
    [self.navigationController pushViewController:hogChildController animated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    self.secondaryControllers = nil;
    self.secondaryItems = nil;
    self.hatArray = nil;
    self.teamDictionary = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [secondaryControllers release];
    [secondaryItems release];
    [hatArray release];
    [teamDictionary release];
    [super dealloc];
}


@end

