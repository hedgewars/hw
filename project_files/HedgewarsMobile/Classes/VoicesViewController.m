/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import "VoicesViewController.h"


@implementation VoicesViewController
@synthesize teamDictionary, voiceArray, lastIndexPath;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    voiceBeingPlayed = NULL;

    // load all the voices names and store them into voiceArray
    // it's here and not in viewWillAppear because user cannot add/remove them
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:VOICES_DIRECTORY() error:NULL];
    self.voiceArray = array;

    self.title = NSLocalizedString(@"Set hedgehog voices",@"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // this moves the tableview to the top
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    Mix_OpenAudio(44100, 0x8010, 1, 1024);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if(voiceBeingPlayed != NULL) {
        Mix_HaltChannel(lastChannel);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }
    Mix_CloseAudio();
}


#pragma mark -
#pragma mark Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.voiceArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
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
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger newRow = [indexPath row];
    NSInteger oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        [teamDictionary setObject:[voiceArray objectAtIndex:newRow] forKey:@"voicepack"];

        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
        [self.tableView reloadData];

        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    // stop any sound before playing another one
    if (voiceBeingPlayed != NULL) {
        Mix_HaltChannel(lastChannel);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }

    NSString *voiceDir = [[NSString alloc] initWithFormat:@"%@/%@/",VOICES_DIRECTORY(),[voiceArray objectAtIndex:newRow]];
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:voiceDir error:NULL];

    int index = arc4random_uniform((int)[array count]);

    voiceBeingPlayed = Mix_LoadWAV([[voiceDir stringByAppendingString:[array objectAtIndex:index]] UTF8String]);
    lastChannel = Mix_PlayChannel(-1, voiceBeingPlayed, 0);
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    if (voiceBeingPlayed != NULL) {
        Mix_HaltChannel(lastChannel);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }
    self.lastIndexPath = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    if (voiceBeingPlayed != NULL) {
        Mix_HaltChannel(lastChannel);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }
}

@end

