//
//  FlagsViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FortsViewController.h"
#import "CommodityFunctions.h"
#import "UIImageScale.h"

@implementation FortsViewController
@synthesize teamDictionary, fortArray, fortSprites, lastIndexPath;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *fortsDirectory = FORTS_DIRECTORY();
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: fortsDirectory error:NULL];
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
    
    //NSLog(@"%@",fortArray);
    
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
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/


#pragma mark -
#pragma mark Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [fortArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.imageView.image = [fortSprites objectAtIndex:[indexPath row]];
    cell.textLabel.text = [fortArray objectAtIndex:[indexPath row]];
    cell.detailTextLabel.text = @"Insert funny description here";
    if ([cell.textLabel.text isEqualToString:[self.teamDictionary objectForKey:@"fort"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
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
-(void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    
    if (newRow != oldRow) {
        // if the two selected rows differ update data on the hog dictionary and reload table content
        [self.teamDictionary setValue:[fortArray objectAtIndex:newRow] forKey:@"fort"];

        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
        [self.tableView reloadData];

        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

-(CGFloat) tableView:(UITableView *)atableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 200;
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
    self.fortSprites = nil;
    [super viewDidUnload];
}


- (void)dealloc {
    [teamDictionary release];
    [lastIndexPath release];
    [fortArray release];
    [fortSprites release];
    [super dealloc];
}


@end

