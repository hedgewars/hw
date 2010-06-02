//
//  GravesViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GravesViewController.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

@implementation GravesViewController
@synthesize teamDictionary, graveArray, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    // load all the grave names and store them into graveArray
    self.graveArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:GRAVES_DIRECTORY() error:NULL];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    // this moves the tableview to the top
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.graveArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    
    NSString *grave = [graveArray objectAtIndex:[indexPath row]];
    cell.textLabel.text = [grave stringByDeletingPathExtension];
    
    if ([grave isEqualToString:[teamDictionary objectForKey:@"grave"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    NSString *graveFilePath = [[NSString alloc] initWithFormat:@"%@/%@",GRAVES_DIRECTORY(),grave];
    // because we also have multi frame graves, let's take the first one only
    UIImage *graveSprite = [[UIImage alloc] initWithContentsOfFile:graveFilePath andCutAt:CGRectMake(0, 0, 32, 32)];
    [graveFilePath release];        
    cell.imageView.image = graveSprite;
    [graveSprite release];
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    
    if (newRow != oldRow) {
        [teamDictionary setObject:[[graveArray objectAtIndex:newRow] stringByDeletingPathExtension] forKey:@"grave"];
        
        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
        
        UITableViewCell *newCell = [aTableView cellForRowAtIndexPath:indexPath];
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        UITableViewCell *oldCell = [aTableView cellForRowAtIndexPath:lastIndexPath];
        oldCell.accessoryType = UITableViewCellAccessoryNone;
        self.lastIndexPath = indexPath;
        [aTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.lastIndexPath = nil;
    self.teamDictionary = nil;
    self.graveArray = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}

- (void)dealloc {
    [graveArray release];
    [teamDictionary release];
    [lastIndexPath release];
    [super dealloc];
}


@end

