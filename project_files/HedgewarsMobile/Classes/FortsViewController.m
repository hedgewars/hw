//
//  FortsViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FortsViewController.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

@implementation FortsViewController
@synthesize teamDictionary, fortArray, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:FORTS_DIRECTORY() error:NULL];
    NSMutableArray *filteredContents = [[NSMutableArray alloc] initWithCapacity:([directoryContents count] / 2)];
    // we need to remove the double entries and the L.png suffix
    for (int i = 0; i < [directoryContents count]; i++) {
        if (i % 2) {
            NSString *currentName = [directoryContents objectAtIndex:i];
            NSString *correctName = [currentName substringToIndex:([currentName length] - 5)];
            [filteredContents addObject:correctName];
        } 
    }
    self.fortArray = filteredContents;
    [filteredContents release];
    
    /*
    // this creates a scaled down version of the image
    NSMutableArray *spriteArray = [[NSMutableArray alloc] initWithCapacity:[fortArray count]];
    for (NSString *fortName in fortArray) {
        NSString *fortFile = [[NSString alloc] initWithFormat:@"%@/%@L.png", fortsDirectory, fortName];
        UIImage *fortSprite = [[UIImage alloc] initWithContentsOfFile:fortFile];
        [fortFile release];
        [spriteArray addObject:[fortSprite scaleToSize:CGSizeMake(196,196)]];
        [fortSprite release];
    }
    self.fortSprites = spriteArray;
    [spriteArray release];
    */
    
    // statically set row height instead of using delegate method for performance reasons
    self.tableView.rowHeight = 200;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fortArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *fortName = [fortArray objectAtIndex:[indexPath row]];
    cell.textLabel.text = fortName;
    
    // this creates a scaled down version of the image
    // TODO: create preview files, scaling is way too slow!
    NSString *fortFile = [[NSString alloc] initWithFormat:@"%@/%@L.png", FORTS_DIRECTORY(), fortName];
    UIImage *fortSprite = [[UIImage alloc] initWithContentsOfFile:fortFile];
    [fortFile release];
    cell.imageView.image = [fortSprite scaleToSize:CGSizeMake(196,196)];
    [fortSprite release];
    
    cell.detailTextLabel.text = @"Insert funny description here";
    if ([cell.textLabel.text isEqualToString:[self.teamDictionary objectForKey:@"fort"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    
    if (newRow != oldRow) {
        // if the two selected rows differ update data on the hog dictionary and reload table content
        [self.teamDictionary setValue:[fortArray objectAtIndex:newRow] forKey:@"fort"];

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
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    self.teamDictionary = nil;
    self.lastIndexPath = nil;
    self.fortArray = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}


- (void)dealloc {
    [teamDictionary release];
    [lastIndexPath release];
    [fortArray release];
//    [fortSprites release];
    [super dealloc];
}


@end

