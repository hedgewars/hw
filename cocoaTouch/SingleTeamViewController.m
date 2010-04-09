//
//  SingleTeamViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SingleTeamViewController.h"
//#import "HogNameViewController.h"
#import "HogHatViewController.h"
#import "FlagsViewController.h"
#import "FortsViewController.h"
#import "CommodityFunctions.h"

@implementation SingleTeamViewController
@synthesize teamDictionary, hatArray, secondaryItems, secondaryControllers, textFieldBeingEdited;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


#pragma mark -
#pragma mark textfield methods
// return to previous table
-(void) cancel:(id) sender {
    if (textFieldBeingEdited != nil)
        [self.textFieldBeingEdited resignFirstResponder];
}

// set the new value
-(void) save:(id) sender {
    if (textFieldBeingEdited != nil) {
        //replace the old value with the new one
        NSDictionary *oldHog = [[teamDictionary objectForKey:@"hedgehogs"] objectAtIndex:selectedHog];
        NSMutableDictionary *newHog = [[NSMutableDictionary alloc] initWithDictionary: oldHog];
        [newHog setObject:textFieldBeingEdited.text forKey:@"hogname"];
        [[teamDictionary objectForKey:@"hedgehogs"] replaceObjectAtIndex:selectedHog withObject:newHog];
        [newHog release];
        
        isWriteNeeded = YES;
        [self.textFieldBeingEdited resignFirstResponder];
    }
}

// the textfield is being modified, update the navigation controller
-(void) textFieldDidBeginEditing:(UITextField *)aTextField{
    self.textFieldBeingEdited = aTextField;
    selectedHog = aTextField.tag;
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
- (void)viewDidLoad {
    [super viewDidLoad];
   
    // labels for the entries
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:
                             NSLocalizedString(@"Grave",@""),
                             NSLocalizedString(@"Voice",@""),
                             NSLocalizedString(@"Fort",@""),
                             NSLocalizedString(@"Flag",@""),
                             NSLocalizedString(@"Level",@""),nil];
    self.secondaryItems = array;
    [array release];
    
    // insert controllers here
    NSMutableArray *controllersArray = [[NSMutableArray alloc] initWithCapacity:[secondaryItems count]];
    
    FlagsViewController *flagsViewController = [[FlagsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [controllersArray addObject:flagsViewController];
    [flagsViewController release];
    
    FortsViewController *fortsViewController = [[FortsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [controllersArray addObject:fortsViewController];
    [fortsViewController release];
    
    self.secondaryControllers = controllersArray;
    [controllersArray release];

    // listen if any childController modifies the plist and write it if needed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWriteNeeded) name:@"setWriteNeedTeams" object:nil];
    isWriteNeeded = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // load data about the team and write if there has been a change
    NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.title];
    if (isWriteNeeded) {
        [self.teamDictionary writeToFile:teamFile atomically:YES];
        NSLog(@"writing: %@",teamDictionary);
        isWriteNeeded = NO;
    }
    
	NSMutableDictionary *teamDict = [[NSMutableDictionary alloc] initWithContentsOfFile:teamFile];
    self.teamDictionary = teamDict;
    [teamDict release];
	[teamFile release];
        
    // load the images of the hat for aach hog
    NSArray *hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[hogArray count]];
    for (NSDictionary *hog in hogArray) {
        NSString *hatFile = [[NSString alloc] initWithFormat:@"%@/%@.png",HATS_DIRECTORY(),[hog objectForKey:@"hat"]];

        UIImage *image = [[UIImage alloc] initWithContentsOfFile: hatFile];
        [hatFile release];
        CGRect firstSpriteArea = CGRectMake(0, 0, 32, 32);
        CGImageRef cgImgage = CGImageCreateWithImageInRect([image CGImage], firstSpriteArea);
        [image release];
        
        UIImage *hatSprite = [[UIImage alloc] initWithCGImage:cgImgage];
        [array addObject:hatSprite];
        CGImageRelease(cgImgage);
        [hatSprite release];
    }
    self.hatArray = array;
    [array release];
    
    [self.tableView reloadData];
}

// write on file if there has been a change
-(void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	NSString *teamFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",TEAMS_DIRECTORY(),self.title];
    if (isWriteNeeded) {
        [self.teamDictionary writeToFile:teamFile atomically:YES];
        NSLog(@"writing: %@",teamDictionary);
        isWriteNeeded = NO;
    }

	[teamFile release];
}

// needed by other classes to warn about a user change
-(void) setWriteNeeded {
    isWriteNeeded = YES;
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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier] autorelease];
        if ([indexPath section] == 1) {
            // create a uitextfield for each row, expand it to take the maximum size
            UITextField *aTextField = [[UITextField alloc] 
                                       initWithFrame:CGRectMake(42, 12, (cell.frame.size.width + cell.frame.size.width/3) - 42, 25)];
            aTextField.clearsOnBeginEditing = NO;
            aTextField.returnKeyType = UIReturnKeyDone;
            aTextField.adjustsFontSizeToFitWidth = YES;
            aTextField.delegate = self;
            aTextField.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 2];
            aTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            [aTextField addTarget:self action:@selector(save:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [cell.contentView addSubview:aTextField];
            [aTextField release];
        }
    }

    NSArray *hogArray;
    NSInteger row = [indexPath row];
    switch ([indexPath section]) {
        case 0:
            cell.textLabel.text = self.title;
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 1:
            hogArray = [self.teamDictionary objectForKey:@"hedgehogs"];

            cell.imageView.image = [self.hatArray objectAtIndex:row];
            
            for (UIView *oneView in cell.contentView.subviews) {
                if ([oneView isMemberOfClass:[UITextField class]]) {
                    // we find the uitextfied and we'll use its tag to understand which one is being edited
                    UITextField *textFieldFound = (UITextField *)oneView;
                    textFieldFound.text = [[hogArray objectAtIndex:row] objectForKey:@"hogname"];
                    textFieldFound.tag = row;
                }
            }

            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            break;
        case 2:
            cell.textLabel.text = [self.secondaryItems objectAtIndex:row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (row) {
                case 3: // flags
                    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png",
                                                                             FLAGS_DIRECTORY(),[teamDictionary objectForKey:@"flag"]]];
                    break;
                default:
                    cell.imageView.image = nil;
                    break;
            }
            break;
        default:
            break;
    }
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    UITableViewController *nextController;
    if (1 == [indexPath section]) {
        UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
        for (UIView *oneView in cell.contentView.subviews) {
            if ([oneView isMemberOfClass:[UITextField class]]) {
                textFieldBeingEdited = (UITextField *)oneView;
                textFieldBeingEdited.tag = row;
                [textFieldBeingEdited becomeFirstResponder];
            }
        }
        [aTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    if (2 == [indexPath section]) {
        //TODO: this part should be rewrittend with lazy loading instead of an array of controllers
        nextController = [secondaryControllers objectAtIndex:row%2 ];              //TODO: fix the objectAtIndex
        nextController.title = [secondaryItems objectAtIndex:row];
        [nextController setTeamDictionary:teamDictionary];
        [self.navigationController pushViewController:nextController animated:YES];
    }
}

// action to perform when you want to change a hog hat
-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (nil == hogChildController) {
        hogChildController = [[HogHatViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    // cache the dictionary file of the team, so that other controllers can modify it
    hogChildController.teamDictionary = self.teamDictionary;
    hogChildController.selectedHog = [indexPath row];
    
    [self.navigationController pushViewController:hogChildController animated:YES];
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
    self.hatArray = nil;
    self.secondaryItems = nil;
    self.secondaryControllers = nil;
    hogChildController = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [teamDictionary release];
    [textFieldBeingEdited release];
    [hatArray release];
    [secondaryItems release];
    [secondaryControllers release];
    [hogChildController release];
    [super dealloc];
}


@end

