//
//  HogHatViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GravesViewController.h"
#import "CommodityFunctions.h"


@implementation GravesViewController
@synthesize teamDictionary, graveArray, graveSprites, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // load all the voices names and store them into voiceArray
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:GRAVES_DIRECTORY() error:NULL];
    self.graveArray = array;
    
    NSMutableArray *sprites = [[NSMutableArray alloc] initWithCapacity:[graveArray count]];
    for (NSString *graveName in graveArray) {
        NSString *gravePath = [[NSString alloc] initWithFormat:@"%@/%@",GRAVES_DIRECTORY(),graveName];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:gravePath];
        [gravePath release];
        
        // because we also have multi frame graves, let's take the first one only
        if (image.size.height > 32) {
            CGRect firstSpriteArea = CGRectMake(0, 0, 32, 32);
            CGImageRef cgImage = CGImageCreateWithImageInRect([image CGImage], firstSpriteArea);
            [image release];
            image = [[UIImage alloc] initWithCGImage:cgImage];
            CGImageRelease(cgImage);
        }
        [sprites addObject:image];
        [image release];
    }
    self.graveSprites = sprites;
    [sprites release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // this moves the tableview to the top
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
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.graveArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *grave = [[graveArray objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
    cell.textLabel.text = grave;
    
    if ([grave isEqualToString:[teamDictionary objectForKey:@"grave"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.imageView.image = [graveSprites objectAtIndex:[indexPath row]];
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
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    
    if (newRow != oldRow) {
        [teamDictionary setObject:[[graveArray objectAtIndex:newRow] stringByDeletingPathExtension] forKey:@"grave"];
        
        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
        [self.tableView reloadData];
        
        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    [super viewDidUnload];
    self.lastIndexPath = nil;
    self.teamDictionary = nil;
    self.graveArray = nil;
    self.graveSprites = nil;
}

- (void)dealloc {
    [graveSprites release];
    [graveArray release];
    [teamDictionary release];
    [lastIndexPath release];
    [super dealloc];
}


@end

