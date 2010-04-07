//
//  HogHatViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HogHatViewController.h"


@implementation HogHatViewController
@synthesize teamDictionary, hatArray, hatSprites, lastIndexPath, selectedHog;

#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // load all the hat file names and store them into hatArray
    NSString *hatPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Data/Graphics/Hats/"];
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:hatPath error:NULL];
    self.hatArray = array;
    
    // load all the hat images from the previous array but save only the first sprite and store it in hatSprites
    NSMutableArray *spriteArray = [[NSMutableArray alloc] initWithCapacity:[hatArray count]];
    for (int i=0; i< [hatArray count]; i++) {
        NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/Data/Graphics/Hats/%@",[[NSBundle mainBundle] resourcePath],[hatArray objectAtIndex:i]];
        
        UIImage *image = [[UIImage alloc] initWithContentsOfFile: hatFile];
        [hatFile release];
        CGRect firstSpriteArea = CGRectMake(0, 0, 32, 32);
        CGImageRef cgImgage = CGImageCreateWithImageInRect([image CGImage], firstSpriteArea);
        [image release];
        
        UIImage *hatSprite = [[UIImage alloc] initWithCGImage:cgImgage];
        [spriteArray addObject:hatSprite];
        CGImageRelease(cgImgage);
        [hatSprite release];
    }
    self.hatSprites = spriteArray;
    [spriteArray release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = [[[teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:selectedHog] objectForKey:@"hogname"];

    // this updates the hog name and its hat
    [self.tableView reloadData];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows;
    if (0 == section) 
        rows = 1;
    else
        rows = [self.hatArray count];
    return rows;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary *hog = [[teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:selectedHog];
    if (0 == [indexPath section]) {
        cell.textLabel.text = self.title;
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.textLabel.text = [[hatArray objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
        if ([cell.textLabel.text isEqualToString:[hog objectForKey:@"hat"]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.lastIndexPath = indexPath;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.imageView.image = [hatSprites objectAtIndex:[indexPath row]];
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

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (1 == [indexPath section]) {
        int newRow = [indexPath row];
        int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
        
        if (newRow != oldRow) {
            // if the two selected rows differ update data on the hog dictionary and reload table content
            NSDictionary *oldHog = [[teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:selectedHog];

            NSMutableDictionary *newHog = [[NSMutableDictionary alloc] initWithDictionary: oldHog];
            [newHog setObject:[[hatArray objectAtIndex:newRow] stringByDeletingPathExtension] forKey:@"hat"];
            [[teamDictionary objectForKey:@"hedgehogs"] replaceObjectAtIndex:selectedHog withObject:newHog];
            [newHog release];
            
            // tell our boss to write this new stuff on disk
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
            [self.tableView reloadData];

            self.lastIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        } 
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
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
    self.hatSprites = nil;
    self.teamDictionary = nil;
    self.hatArray = nil;
}

- (void)dealloc {
    [hatArray release];
    [teamDictionary release];
    [hatSprites release];
    [lastIndexPath release];
    [super dealloc];
}


@end

