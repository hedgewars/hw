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


#import "SavedGamesViewController.h"
#import "GameInterfaceBridge.h"


@implementation SavedGamesViewController
@synthesize tableView, listOfSavegames;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) updateTable {
    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:SAVES_DIRECTORY() error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:contentsOfDir copyItems:YES];
    self.listOfSavegames = array;
    [array release];

    [self.tableView reloadData];
}

-(void) viewDidLoad {
    [self.tableView setBackgroundColorForAnyTable:[UIColor clearColor]];

    NSString *imgName = (IS_IPAD()) ? @"mediumBackground~ipad.png" : @"smallerBackground~iphone.png";
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgName];
    UIImageView *background = [[UIImageView alloc] initWithImage:img];
    [img release];
    background.frame = self.view.frame;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:background atIndex:0];
    [background release];

    if (self.listOfSavegames == nil)
        [self updateTable];
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    [self updateTable];
    [super viewWillAppear:animated];
}

#pragma mark -
#pragma mark button functions
-(IBAction) buttonPressed:(id) sender {
    UIButton *button = (UIButton *)sender;

    if (button.tag == 0) {
        [[AudioManagerController mainManager] playBackSound];
        [self.tableView setEditing:NO animated:YES];
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } else {
        NSString *titleStr, *cancelStr, *confirmStr;
        titleStr = NSLocalizedString(@"Are you reeeeeally sure?", @"");
        cancelStr = NSLocalizedString(@"Well, maybe not...", @"");
        confirmStr = NSLocalizedString(@"Of course!", @"");

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:titleStr
                                                                 delegate:self
                                                        cancelButtonTitle:cancelStr
                                                   destructiveButtonTitle:confirmStr
                                                        otherButtonTitles:nil];

        if (IS_IPAD())
            [actionSheet showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
        else
            [actionSheet showInView:self.view];
        [actionSheet release];
    }
}

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
    if ([actionSheet cancelButtonIndex] != buttonIndex) {
        // remove all files and recreate the directory
        [[NSFileManager defaultManager] removeItemAtPath:SAVES_DIRECTORY() error:NULL];
        [[NSFileManager defaultManager] createDirectoryAtPath:SAVES_DIRECTORY() withIntermediateDirectories:NO attributes:nil error:NULL];

        // update the table and the cached list
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (int i = 0; i < [self.listOfSavegames count]; i++)
            [array addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        [self.listOfSavegames removeAllObjects];
        
        [self.tableView deleteRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationTop];
        [array release];
    }
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfSavegames count];
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    EditableCellView *editableCell = (EditableCellView *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (editableCell == nil) {
        editableCell = [[[EditableCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        editableCell.delegate = nil;
        editableCell.textField.userInteractionEnabled = NO;
    }
    editableCell.tag = [indexPath row];
    editableCell.textField.text = [[self.listOfSavegames objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
    editableCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return (UITableViewCell *)editableCell;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger) section {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)];
    footer.backgroundColor = [UIColor clearColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width*60/100, 60)];
    label.center = CGPointMake(self.tableView.frame.size.width/2, 30);
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont italicSystemFontOfSize:16];
    label.textColor = [UIColor lightGrayColor];
    label.numberOfLines = 5;
    label.text = NSLocalizedString(@"Press to resume playing or swipe to delete the save file.",@"");

    label.backgroundColor = [UIColor clearColor];
    [footer addSubview:label];
    [label release];
    return [footer autorelease];
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 60;
}

-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [(EditableCellView *)[self.tableView cellForRowAtIndexPath:indexPath] save:nil];
    [self fixTagsForStartTag:[indexPath row]];

    NSString *saveName = [self.listOfSavegames objectAtIndex:[indexPath row]];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",SAVES_DIRECTORY(),saveName];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    [self.listOfSavegames removeObject:saveName];
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark - Fix cells' tags

- (void)fixTagsForStartTag:(NSInteger)tag
{
    for (UITableViewCell *cell in self.tableView.visibleCells)
    {
        NSInteger oldTag = cell.tag;
        
        if (oldTag > tag)
        {
            cell.tag--;
        }
    }
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.listOfSavegames == nil)
        [self updateTable];

    // duplicate the entry
    [(EditableCellView *)[self.tableView cellForRowAtIndexPath:indexPath] save:nil];

    NSString *currentSaveName = [self.listOfSavegames objectAtIndex:[indexPath row]];
    NSString *currentFilePath = [[NSString alloc] initWithFormat:@"%@/%@",SAVES_DIRECTORY(),currentSaveName];
    NSString *newSaveName = [[NSString alloc] initWithFormat:@"[%@] %@",NSLocalizedString(@"Backup",@""),currentSaveName];
    NSString *newFilePath = [[NSString alloc] initWithFormat:@"%@/%@",SAVES_DIRECTORY(),newSaveName];

    [self.listOfSavegames addObject:newSaveName];
    [newSaveName release];
    [[NSFileManager defaultManager] copyItemAtPath:currentFilePath toPath:newFilePath error:nil];
    [newFilePath release];

    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

    [GameInterfaceBridge registerCallingController:self];
    [GameInterfaceBridge startSaveGame:currentFilePath];
    [currentFilePath release];
}

#pragma mark -
#pragma mark editableCellView delegate
// rename old file if names differ
-(void) saveTextFieldValue:(NSString *)textString withTag:(NSInteger) tagValue {
    if (self.listOfSavegames == nil)
        [self updateTable];
    NSString *oldFilePath = [NSString stringWithFormat:@"%@/%@",SAVES_DIRECTORY(),[self.listOfSavegames objectAtIndex:tagValue]];
    NSString *newFilePath = [NSString stringWithFormat:@"%@/%@.hws",SAVES_DIRECTORY(),textString];

    if ([oldFilePath isEqualToString:newFilePath] == NO) {
        [[NSFileManager defaultManager] moveItemAtPath:oldFilePath toPath:newFilePath error:nil];
        [self.listOfSavegames replaceObjectAtIndex:tagValue withObject:[textString stringByAppendingString:@".hws"]];
    }

}

#pragma mark -
#pragma mark Memory Management
-(void) didReceiveMemoryWarning {
    self.listOfSavegames = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.tableView = nil;
    self.listOfSavegames = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(tableView);
    releaseAndNil(listOfSavegames);
    [super dealloc];
}

@end
