//
//  VoicesViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VoicesViewController.h"
#import "CommodityFunctions.h"
#import "openalbridge.h"


@implementation VoicesViewController
@synthesize teamDictionary, voiceArray, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    srandom(time(NULL));

    openal_init(20);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // this moves the tableview to the top
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
    voiceBeingPlayed = -1;

    // load all the voices names and store them into voiceArray
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:VOICES_DIRECTORY() error:NULL];
    self.voiceArray = array;
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(voiceBeingPlayed >= 0) {
        openal_stopsound(voiceBeingPlayed);
        voiceBeingPlayed = -1;
    }
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.voiceArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *voice = [[voiceArray objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
    cell.textLabel.text = voice;
    
    if ([voice isEqualToString:[teamDictionary objectForKey:@"voicepack"]]) {
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
        [teamDictionary setObject:[voiceArray objectAtIndex:newRow] forKey:@"voicepack"];
        
        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
        [self.tableView reloadData];
        
        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } 
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (voiceBeingPlayed >= 0) {
        openal_stopsound(voiceBeingPlayed);
        voiceBeingPlayed = -1;
    }
    
    // the keyword static prevents re-initialization of the variable
    NSString *voiceDir = [[NSString alloc] initWithFormat:@"%@/%@/",VOICES_DIRECTORY(),[voiceArray objectAtIndex:newRow]];
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:voiceDir error:NULL];
    
    int index = random() % [array count];
    
    voiceBeingPlayed = openal_loadfile([[voiceDir stringByAppendingString:[array objectAtIndex:index]] UTF8String]);
    [voiceDir release];
    openal_playsound(voiceBeingPlayed);    
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    openal_close();
    voiceBeingPlayed = -1;
    self.lastIndexPath = nil;
    self.teamDictionary = nil;
    self.voiceArray = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}

-(void) dealloc {
    [voiceArray release];
    [teamDictionary release];
    [lastIndexPath release];
    [super dealloc];
}


@end

