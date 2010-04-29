//
//  SingleTeamViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SingleTeamViewController.h"
#import "HogHatViewController.h"
#import "GravesViewController.h"
#import "VoicesViewController.h"
#import "FortsViewController.h"
#import "FlagsViewController.h"
#import "LevelViewController.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

#define TEAMNAME_TAG 1234

@implementation SingleTeamViewController
@synthesize teamDictionary, normalHogSprite, secondaryItems, textFieldBeingEdited, teamName;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark textfield methods
// return to previous table
-(void) cancel:(id) sender {
    if (textFieldBeingEdited != nil)
        [self.textFieldBeingEdited resignFirstResponder];
}

// set the new value
-(BOOL) save:(id) sender {
    NSInteger index = textFieldBeingEdited.tag;
    
    if (textFieldBeingEdited != nil) {
        if (TEAMNAME_TAG == index) {
            [self.teamDictionary setObject:textFieldBeingEdited.text forKey:@"teamname"];
        } else {
            //replace the old value with the new one            
            NSMutableDictionary *hog = [[teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:index];
            [hog setObject:textFieldBeingEdited.text forKey:@"hogname"];
        }
        
        isWriteNeeded = YES;
        [self.textFieldBeingEdited resignFirstResponder];
        return YES;
    }
    return NO;
}

// the textfield is being modified, update the navigation controller
-(void) textFieldDidBeginEditing:(UITextField *)aTextField{   
    self.textFieldBeingEdited = aTextField;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",@"from the hog name table")
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",@"from the hog name table")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
}

// the textfield has been modified, check for empty strings and restore original navigation bar
-(void) textFieldDidEndEditing:(UITextField *)aTextField{
    if ([textFieldBeingEdited.text length] == 0) 
        textFieldBeingEdited.text = [NSString stringWithFormat:@"hedgehog %d",textFieldBeingEdited.tag];

    self.textFieldBeingEdited = nil;
    self.navigationItem.rightBarButtonItem = self.navigationItem.backBarButtonItem;
    self.navigationItem.leftBarButtonItem = nil;
}

// limit the size of the field to 64 characters like in original frontend
-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    int limit = 64;
    return !([textField.text length] > limit && [string length] > range.length);
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

    // load the base hog image, drawing will occure in cellForRow...
    NSString *normalHogFile = [[NSString alloc] initWithFormat:@"%@/Hedgehog.png",GRAPHICS_DIRECTORY()];
    UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:normalHogFile andCutAt:CGRectMake(96, 0, 32, 32)];
    [normalHogFile release];
    self.normalHogSprite = hogSprite;
    [hogSprite release];
    
    // listen if any childController modifies the plist and write it if needed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWriteNeeded) name:@"setWriteNeedTeams" object:nil];
    isWriteNeeded = NO;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // load data about the team and write if there has been a change
    if (isWriteNeeded) 
        [self writeFile];
    
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.title];
	NSMutableDictionary *teamDict = [[NSMutableDictionary alloc] initWithContentsOfFile:teamFile];
    self.teamDictionary = teamDict;
    [teamDict release];
	[teamFile release];
    
    self.teamName = self.title;
    
    [self.tableView reloadData];
}

// write on file if there has been a change
-(void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

    // end the editing of the current field
    if (textFieldBeingEdited != nil) {
        [self save:nil];
    }
    
    if (isWriteNeeded) 
        [self writeFile];        
}

#pragma mark -
// needed by other classes to warn about a user change
-(void) setWriteNeeded {
    isWriteNeeded = YES;
}

-(void) writeFile {
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.title];

    NSString *newTeamName = [self.teamDictionary objectForKey:@"teamname"];
    if (![newTeamName isEqualToString:self.teamName]) {
        //delete old
        [[NSFileManager defaultManager] removeItemAtPath:teamFile error:NULL];
        [teamFile release];
        self.title = newTeamName;
        self.teamName = newTeamName;
        teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),newTeamName];
    }
    
    [self.teamDictionary writeToFile:teamFile atomically:YES];
    NSLog(@"writing: %@",teamDictionary);
    isWriteNeeded = NO;
	[teamFile release];
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
            rows = MAX_HOGS;
            break;
        case 2: // team details
            rows = [self.secondaryItems count];
            break;
        default:
            break;
    }
    return rows;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";
    static NSString *CellIdentifier2 = @"Cell2";
    
    NSArray *hogArray;
    UITableViewCell *cell = nil;
    NSInteger row = [indexPath row];
    UIImage *accessoryImage;
    
    switch ([indexPath section]) {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier0];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier0] autorelease];
                // create a uitextfield for each row, expand it to take the maximum size
                UITextField *aTextField = [[UITextField alloc] 
                                           initWithFrame:CGRectMake(5, 12, (cell.frame.size.width + cell.frame.size.width/3) - 42, 25)];
                aTextField.clearsOnBeginEditing = NO;
                aTextField.returnKeyType = UIReturnKeyDone;
                aTextField.adjustsFontSizeToFitWidth = YES;
                aTextField.delegate = self;
                aTextField.tag = [indexPath row];
                aTextField.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 2];
                aTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                [aTextField addTarget:self action:@selector(save:) forControlEvents:UIControlEventEditingDidEndOnExit];
                [cell.contentView addSubview:aTextField];
                [aTextField release];
            }
            
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            for (UIView *oneView in cell.contentView.subviews) {
                if ([oneView isMemberOfClass:[UITextField class]]) {
                    // we find the uitextfied and we'll use its tag to understand which one is being edited
                    UITextField *textFieldFound = (UITextField *)oneView;
                    textFieldFound.text = [self.teamDictionary objectForKey:@"teamname"];
                    textFieldFound.tag = TEAMNAME_TAG;
                }
            }            
            break;
        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier1] autorelease];
                
                // create a uitextfield for each row, expand it to take the maximum size
                UITextField *aTextField = [[UITextField alloc] 
                                           initWithFrame:CGRectMake(42, 12, (cell.frame.size.width + cell.frame.size.width/3) - 42, 25)];
                aTextField.clearsOnBeginEditing = NO;
                aTextField.returnKeyType = UIReturnKeyDone;
                aTextField.adjustsFontSizeToFitWidth = YES;
                aTextField.delegate = self;
                aTextField.tag = [indexPath row];
                aTextField.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 2];
                aTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                [aTextField addTarget:self action:@selector(save:) forControlEvents:UIControlEventEditingDidEndOnExit];
                [cell.contentView addSubview:aTextField];
                [aTextField release];
            }
            
            hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];
            
            NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@.png", HATS_DIRECTORY(), [[hogArray objectAtIndex:row] objectForKey:@"hat"]];
            UIImage *hatSprite = [[UIImage alloc] initWithContentsOfFile: hatFile andCutAt:CGRectMake(0, 0, 32, 32)];
            [hatFile release];
            cell.imageView.image = [self.normalHogSprite mergeWith:hatSprite atPoint:CGPointMake(0, -5)];
            [hatSprite release];
                        
            for (UIView *oneView in cell.contentView.subviews) {
                if ([oneView isMemberOfClass:[UITextField class]]) {
                    // we find the uitextfied and we'll use its tag to understand which one is being edited
                    UITextField *textFieldFound = (UITextField *)oneView;
                    textFieldFound.text = [[hogArray objectAtIndex:row] objectForKey:@"hogname"];
                }
            }
            
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            break;
        case 2:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier2] autorelease];
            }
            
            cell.textLabel.text = [self.secondaryItems objectAtIndex:row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (row) {
                case 0: // grave
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png",
                                                                              GRAVES_DIRECTORY(),[teamDictionary objectForKey:@"grave"]]
                                                                    andCutAt:CGRectMake(0,0,32,32)];
                    cell.imageView.image = accessoryImage;
                    [accessoryImage release];
                    break;
                case 2: // fort
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@L.png",
                                                                              FORTS_DIRECTORY(),[teamDictionary objectForKey:@"fort"]]];
                    cell.imageView.image = [accessoryImage scaleToSize:CGSizeMake(42, 42)];
                    [accessoryImage release];
                    break;
                    
                case 3: // flags
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png",
                                                                              FLAGS_DIRECTORY(),[teamDictionary objectForKey:@"flag"]]];
                    cell.imageView.image = accessoryImage;
                    [accessoryImage release];
                    break;
                case 4: // level
                    accessoryImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%d.png",
                                                                              BOTLEVELS_DIRECTORY(),[[[[teamDictionary objectForKey:@"hedgehogs"]
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
    UITableViewController *nextController = nil;
    UITableViewCell *cell;
    
    if (2 == section) {
        switch (row) {
            case 0: // grave
                if (nil == gravesViewController)
                    gravesViewController = [[GravesViewController alloc] initWithStyle:UITableViewStyleGrouped];
                
                nextController = gravesViewController;
                break;
            case 1: // voice
                if (nil == voicesViewController)
                    voicesViewController = [[VoicesViewController alloc] initWithStyle:UITableViewStyleGrouped];
                
                nextController = voicesViewController;                    
                break;
            case 2: // fort
                if (nil == fortsViewController)
                    fortsViewController = [[FortsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                
                nextController = fortsViewController;
                break;
            case 3: // flag
                if (nil == flagsViewController) 
                    flagsViewController = [[FlagsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                
                nextController = flagsViewController;
                break;
            case 4: // level
                if (nil == levelViewController)
                    levelViewController = [[LevelViewController alloc] initWithStyle:UITableViewStyleGrouped];
                
                nextController = levelViewController;
                break;
        }
        
        nextController.title = [secondaryItems objectAtIndex:row];
        [nextController setTeamDictionary:teamDictionary];
        [self.navigationController pushViewController:nextController animated:YES];
    } else {
        cell = [aTableView cellForRowAtIndexPath:indexPath];
        for (UIView *oneView in cell.contentView.subviews) {
            if ([oneView isMemberOfClass:[UITextField class]]) {
                textFieldBeingEdited = (UITextField *)oneView;
                [textFieldBeingEdited becomeFirstResponder];
            }
        }
        [aTableView deselectRowAtIndexPath:indexPath animated:NO];
    }

}

// action to perform when you want to change a hog hat
-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (nil == hogHatViewController) {
        hogHatViewController = [[HogHatViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    // cache the dictionary file of the team, so that other controllers can modify it
    hogHatViewController.teamDictionary = self.teamDictionary;
    hogHatViewController.selectedHog = [indexPath row];
    
    [self.navigationController pushViewController:hogHatViewController animated:YES];
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
    self.textFieldBeingEdited = nil;
    self.teamName = nil;
    self.normalHogSprite = nil;
    self.secondaryItems = nil;
    hogHatViewController = nil;
    flagsViewController = nil;
    fortsViewController = nil;
    gravesViewController = nil;
    levelViewController = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [teamDictionary release];
    [textFieldBeingEdited release];
    [teamName release];
    [normalHogSprite release];
    [secondaryItems release];
    [hogHatViewController release];
    [fortsViewController release];
    [gravesViewController release];
    [flagsViewController release];
    [levelViewController release];
    [super dealloc];
}


@end

