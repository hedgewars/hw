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


#import "SingleTeamViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "HogHatViewController.h"
#import "GravesViewController.h"
#import "VoicesViewController.h"
#import "FortsViewController.h"
#import "FlagsViewController.h"
#import "LevelViewController.h"


#define TEAMNAME_TAG 78789

@implementation SingleTeamViewController
@synthesize teamDictionary, normalHogSprite, secondaryItems, moreSecondaryItems, teamName;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark editableCellViewDelegate methods
// set the new value
-(void) saveTextFieldValue:(NSString *)textString withTag:(NSInteger) tagValue {
    if (TEAMNAME_TAG == tagValue) {
        // delete old file
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.teamName] error:NULL];
        // update filename
        self.teamName = textString;
        // save new file
        [self writeFile];
    } else {
        // replace the old value with the new one
        NSMutableDictionary *hog = [[teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:tagValue];
        [hog setObject:textString forKey:@"hogname"];
        isWriteNeeded = YES;
    }
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    // labels for the entries
    NSArray *array = [[NSArray alloc] initWithObjects:
                      NSLocalizedString(@"Grave",@""),
                      NSLocalizedString(@"Voice",@""),
                      NSLocalizedString(@"Fort",@""),
                      NSLocalizedString(@"Flag",@""),
                      NSLocalizedString(@"Level",@""),nil];
    self.secondaryItems = array;
    [array release];

    // labels for the subtitles
    NSArray *moreArray = [[NSArray alloc] initWithObjects:
                          NSLocalizedString(@"Mark the death of your fallen warriors",@""),
                          NSLocalizedString(@"Pick a slang your hogs will speak",@""),
                          NSLocalizedString(@"Select the team invincible fortress (only valid for fort games)",@""),
                          NSLocalizedString(@"Choose a charismatic symbol for your team",@""),
                          NSLocalizedString(@"Opt for controlling the team or let the AI lead",@""),nil];
    self.moreSecondaryItems = moreArray;
    [moreArray release];

    // load the base hog image, drawing will occure in cellForRow...
    NSString *normalHogFile = [[NSString alloc] initWithFormat:@"%@/basehat-hedgehog.png",[[NSBundle mainBundle] resourcePath]];
    UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:normalHogFile];
    [normalHogFile release];
    self.normalHogSprite = hogSprite;
    [hogSprite release];

    // listen if any childController modifies the plist and write it if needed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWriteNeeded) name:@"setWriteNeedTeams" object:nil];
    isWriteNeeded = NO;

    self.title = NSLocalizedString(@"Edit team settings",@"");
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // load data about the team and write if there has been a change from other childControllers
    if (isWriteNeeded)
        [self writeFile];

    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.teamName];
    NSMutableDictionary *teamDict = [[NSMutableDictionary alloc] initWithContentsOfFile:teamFile];
    self.teamDictionary = teamDict;
    [teamDict release];
    [teamFile release];

    [self.tableView reloadData];
}

// write on file if there has been a change
-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (isWriteNeeded)
        [self writeFile];
}

#pragma mark -
// needed by other classes to warn about a user change
-(void) setWriteNeeded {
    isWriteNeeded = YES;
}

-(void) writeFile {
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.teamName];
    [self.teamDictionary writeToFile:teamFile atomically:YES];
    [teamFile release];

    //DLog(@"%@",teamDictionary);
    isWriteNeeded = NO;
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
            rows = HW_getMaxNumberOfHogs() + 1; // one for 'Select one hat for all hogs' cell
            break;
        case 2: // team details
            rows = [self.secondaryItems count];
            break;
        default:
            break;
    }
    return rows;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = NSLocalizedString(@"Team Name", @"");
            break;
        case 1:
            sectionTitle = NSLocalizedString(@"Names and Hats", @"");
            break;
        case 2:
            sectionTitle = NSLocalizedString(@"Team Preferences", @"");
            break;
        default:
            DLog(@"Nope");
            break;
    }
    return sectionTitle;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";
    static NSString *CellIdentifier2 = @"Cell2";
    static NSString *CellIdentifierDefault = @"CellDefault";

    NSArray *hogArray;
    UITableViewCell *cell = nil;
    EditableCellView *editableCell = nil;
    NSInteger row = [indexPath row];
    UIImage *accessoryImage;

    switch ([indexPath section]) {
        case 0:
            editableCell = (EditableCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier0];
            if (editableCell == nil) {
                editableCell = [[[EditableCellView alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:CellIdentifier0] autorelease];
                editableCell.delegate = self;
                editableCell.tag = TEAMNAME_TAG;
            }

            editableCell.imageView.image = nil;
            editableCell.accessoryType = UITableViewCellAccessoryNone;
            editableCell.textField.text = self.teamName;

            cell = editableCell;
            break;
        case 1:
            if ([indexPath row] == HW_getMaxNumberOfHogs())
            {
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierDefault];
                if (cell == nil)
                {
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:CellIdentifierDefault] autorelease];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                
                cell.textLabel.text = NSLocalizedString(@"Select one hat for all hogs", nil);
                
                break;
            }
            
            editableCell = (EditableCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
            if (editableCell == nil) {
                editableCell = [[[EditableCellView alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:CellIdentifier1] autorelease];
                editableCell.delegate = self;
            }
            editableCell.tag = [indexPath row];

            hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];

            // draw the hat on top of the hog
            NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@.png", HATS_DIRECTORY(), [[hogArray objectAtIndex:row] objectForKey:@"hat"]];
            UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile: hatFile andCutAt:CGRectMake(0, 0, 32, 32)];
            [hatFile release];
            editableCell.imageView.image = [self.normalHogSprite mergeWith:hatSprite atPoint:CGPointMake(0, 5)];
            [hatSprite release];

            editableCell.textField.text = [[hogArray objectAtIndex:row] objectForKey:@"hogname"];
            editableCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

            cell = editableCell;
            break;
        case 2:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                               reuseIdentifier:CellIdentifier2] autorelease];
            }

            cell.textLabel.text = [self.secondaryItems objectAtIndex:row];
            cell.detailTextLabel.text = [self.moreSecondaryItems objectAtIndex:row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (row) {
                case 0: // grave
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png",
                                                                              GRAVES_DIRECTORY(),[teamDictionary objectForKey:@"grave"]]
                                                                    andCutAt:CGRectMake(0,0,32,32)];
                    cell.imageView.image = accessoryImage;
                    [accessoryImage release];
                    break;
                case 1: // voice
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/HellishBomb.png",
                                                                              GRAPHICS_DIRECTORY()]];
                    cell.imageView.image = accessoryImage;
                    [accessoryImage release];
                    break;
                case 2: // fort
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@-icon.png",
                                                                              FORTS_DIRECTORY(),[teamDictionary objectForKey:@"fort"]]];
                    cell.imageView.image = accessoryImage;
                    [accessoryImage release];
                    break;
                case 3: // flags
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png",
                                                                              FLAGS_DIRECTORY(),[teamDictionary objectForKey:@"flag"]]];
                    cell.imageView.image = [accessoryImage scaleToSize:CGSizeMake(26, 18)];
                    [accessoryImage release];
                    cell.imageView.layer.borderWidth = 1;
                    cell.imageView.layer.borderColor = [[UIColor blackColor] CGColor];
                    break;
                case 4: // level
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/bot%d.png",
                                                                              [[NSBundle mainBundle] resourcePath],
                                                                              [[[[teamDictionary objectForKey:@"hedgehogs"]
                                                                                 objectAtIndex:0] objectForKey:@"level"]
                                                                               intValue]]];
                    cell.imageView.image = accessoryImage;
                    [accessoryImage release];
                    break;
                default:
                    cell.imageView.image = nil;
                    break;
            }
            break;
    }

    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];

    if (2 == section)
    {
        switch (row)
        {
            case 0: // grave
            {
                GravesViewController *gravesViewController = [[GravesViewController alloc] initWithStyle:UITableViewStyleGrouped];

                [gravesViewController setTeamDictionary:teamDictionary];
                [self.navigationController pushViewController:gravesViewController animated:YES];
                [gravesViewController release];
                break;
            }
            case 1: // voice
            {
                VoicesViewController *voicesViewController = [[VoicesViewController alloc] initWithStyle:UITableViewStyleGrouped];

                [voicesViewController setTeamDictionary:teamDictionary];
                [self.navigationController pushViewController:voicesViewController animated:YES];
                [voicesViewController release];
                break;
            }
            case 2: // fort
            {
                FortsViewController *fortsViewController = [[FortsViewController alloc] initWithStyle:UITableViewStyleGrouped];

                [fortsViewController setTeamDictionary:teamDictionary];
                [self.navigationController pushViewController:fortsViewController animated:YES];
                [fortsViewController release];
                break;
            }
            case 3: // flag
            {
                FlagsViewController *flagsViewController = [[FlagsViewController alloc] initWithStyle:UITableViewStyleGrouped];

                [flagsViewController setTeamDictionary:teamDictionary];
                [self.navigationController pushViewController:flagsViewController animated:YES];
                [flagsViewController release];
                break;
            }
            case 4: // level
            {
                LevelViewController *levelViewController = [[LevelViewController alloc] initWithStyle:UITableViewStyleGrouped];

                [levelViewController setTeamDictionary:teamDictionary];
                [self.navigationController pushViewController:levelViewController animated:YES];
                [levelViewController release];
                break;
            }
            default:
                DLog(@"Nope");
                break;
        }
    } else {
        if (section == 1 && row == HW_getMaxNumberOfHogs()) {
            // 'Select one hat for all hogs' selected
            [self showHogHatViewControllerForHogIndex:-1];
        } else {
            EditableCellView *cell = (EditableCellView *)[aTableView cellForRowAtIndexPath:indexPath];
            [cell replyKeyboard];
            [aTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }

}

// action to perform when you want to change a hog hat
-(void) tableView:(UITableView *)aTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // if we are editing the field undo any change before proceeding
    EditableCellView *cell = (EditableCellView *)[aTableView cellForRowAtIndexPath:indexPath];
    [cell cancel:nil];
    
    [self showHogHatViewControllerForHogIndex:[indexPath row]];
}

- (void)showHogHatViewControllerForHogIndex:(NSInteger)hogIndex
{
    HogHatViewController *hogHatViewController = [[HogHatViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    // cache the dictionary file of the team, so that other controllers can modify it
    hogHatViewController.teamDictionary = self.teamDictionary;
    hogHatViewController.selectedHog = hogIndex;
    
    [self.navigationController pushViewController:hogHatViewController animated:YES];
    [hogHatViewController release];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.teamDictionary = nil;
    self.teamName = nil;
    self.normalHogSprite = nil;
    self.secondaryItems = nil;
    self.moreSecondaryItems = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(teamDictionary);
    releaseAndNil(teamName);
    releaseAndNil(normalHogSprite);
    releaseAndNil(secondaryItems);
    releaseAndNil(moreSecondaryItems);
    [super dealloc];
}


@end

