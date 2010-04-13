//
//  HogHatViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VoicesViewController.h"
#import "CommodityFunctions.h"


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

    Mix_OpenAudio(44100, AUDIO_S16SYS, 2, 1024);
    voiceBeingPlayed = NULL;

    // load all the voices names and store them into voiceArray
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:VOICES_DIRECTORY() error:NULL];
    self.voiceArray = array;
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(voiceBeingPlayed != NULL) {
        Mix_HaltChannel(-1);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }
}

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
    return [self.voiceArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
-(void) allowSelection {
    self.tableView.allowsSelection = YES;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    
    // avoid a crash in sdl_mixer
    self.tableView.allowsSelection = NO;
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(allowSelection) userInfo:nil repeats:NO];
    
    if (newRow != oldRow) {
        [teamDictionary setObject:[voiceArray objectAtIndex:newRow] forKey:@"voicepack"];
        
        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
        [self.tableView reloadData];
        
        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } 
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (voiceBeingPlayed != NULL) {
        Mix_HaltChannel(-1);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }
    
    // the keyword static prevents re-initialization of the variable
    NSString *voiceDir = [[NSString alloc] initWithFormat:@"%@/%@/",VOICES_DIRECTORY(),[voiceArray objectAtIndex:newRow]];
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:voiceDir error:NULL];
    
    int index = random() % [array count];
    
    voiceBeingPlayed = Mix_LoadWAV([[voiceDir stringByAppendingString:[array objectAtIndex:index]] UTF8String]);
    [voiceDir release];
    Mix_PlayChannel(-1, voiceBeingPlayed, 0);    
}


#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning {
    Mix_HaltChannel(-1);
    Mix_FreeChunk(voiceBeingPlayed);
    voiceBeingPlayed = NULL;
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];

    Mix_CloseAudio();
    voiceBeingPlayed = NULL;
    self.lastIndexPath = nil;
    self.teamDictionary = nil;
    self.voiceArray = nil;
}

- (void)dealloc {
    [voiceArray release];
    [teamDictionary release];
    [lastIndexPath release];
    [super dealloc];
}


@end


