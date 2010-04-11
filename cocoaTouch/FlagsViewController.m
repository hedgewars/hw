//
//  FlagsViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FlagsViewController.h"
#import "CommodityFunctions.h"

@implementation FlagsViewController
@synthesize teamDictionary, flagArray, flagSprites, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *flagsDirectory = FLAGS_DIRECTORY();
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:flagsDirectory error:NULL];
    self.flagArray = array;
    
    NSMutableArray *spriteArray = [[NSMutableArray alloc] initWithCapacity:[flagArray count]];
    for (NSString *flagName in flagArray) {
        NSString *flagFile = [[NSString alloc] initWithFormat:@"%@/%@", flagsDirectory, flagName];
        UIImage *flagSprite = [[UIImage alloc] initWithContentsOfFile:flagFile];
        [flagFile release];
        [spriteArray addObject:flagSprite];
        [flagSprite release];
    }
    self.flagSprites = spriteArray;
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
    return [flagArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.imageView.image = [flagSprites objectAtIndex:[indexPath row]];
    cell.textLabel.text = [[flagArray objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
    if ([cell.textLabel.text isEqualToString:[self.teamDictionary objectForKey:@"flag"]]) {
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    
    if (newRow != oldRow) {
        // if the two selected rows differ update data on the hog dictionary and reload table content
        [self.teamDictionary setValue:[[flagArray objectAtIndex:newRow] stringByDeletingPathExtension] forKey:@"flag"];

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
    self.teamDictionary = nil;
    self.lastIndexPath = nil;
    self.flagArray = nil;
    self.flagSprites = nil;
    [super viewDidUnload];
}


- (void)dealloc {
    [teamDictionary release];
    [lastIndexPath release];
    [flagArray release];
    [flagSprites release];
    [super dealloc];
}


@end

