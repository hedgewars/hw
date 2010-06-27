//
//  SingleSchemeViewController.m
//  Hedgewars
//
//  Created by Vittorio on 23/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SingleSchemeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

#define LABEL_TAG  12345
#define SLIDER_TAG 54321

@implementation SingleSchemeViewController
@synthesize textFieldBeingEdited, schemeArray, basicSettingList, gameModifierArray;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    NSArray *mods = [[NSArray alloc] initWithObjects:
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Fort Mode",@""),@"title",
                      NSLocalizedString(@"Defend your fort and destroy the opponents (two team colours max)",@""),@"description",
                      @"Forts",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Divide Team",@""),@"title",
                      NSLocalizedString(@"Teams will start on opposite sides of the terrain (two team colours max)",@""),@"description",
                      @"TeamsDivide",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Solid Land",@""),@"title",
                      NSLocalizedString(@"Land can not be destroyed",@""),@"description",
                      @"Solid",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Add Border",@""),@"title",
                      NSLocalizedString(@"Add an indestructable border around the terrain",@""),@"description",
                      @"Border",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Low Gravity",@""),@"title",
                      NSLocalizedString(@"Lower gravity",@""),@"description",
                      @"LowGravity",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Laser Sight",@""),@"title",
                      NSLocalizedString(@"Assisted aiming with laser sight",@""),@"description",
                      @"LaserSight",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Invulnerable",@""),@"title",
                      NSLocalizedString(@"All hogs have a personal forcefield",@""),@"description",
                      @"Invulnerable",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Add Mines",@""),@"title",
                      NSLocalizedString(@"Enable random mines",@""),@"description",
                      @"Mines",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Vampirism Mode",@""),@"title",
                      NSLocalizedString(@"Gain 80% of the damage you do back in health",@""),@"description",
                      @"Vampiric",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Karma Mode",@""),@"title",
                      NSLocalizedString(@"Share your opponents pain, share their damage",@""),@"description",
                      @"Karma",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Artillery Mode",@""),@"title",
                      NSLocalizedString(@"Your hogs are unable to move, test your aim",@""),@"description",
                      @"Artillery",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Random Order",@""),@"title",
                      NSLocalizedString(@"Order of play is random instead of in room order",@""),@"description",
                      @"RandomOrder",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"King Mode",@""),@"title",
                      NSLocalizedString(@"Play with a King. If he dies, your side loses",@""),@"description",
                      @"King",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"Place Hedgehogs",@""),@"title",
                      NSLocalizedString(@"Take turns placing your hedgehogs pre-game",@""),@"description",
                      @"PlaceHog",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Clan Shares Ammo",@""),@"title",
                      NSLocalizedString(@"Ammo is shared between all clan teams",@""),@"description",
                      @"SharedAmmo",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Disable Girders",@""),@"title",
                      NSLocalizedString(@"Disable girders when generating random maps",@""),@"description",
                      @"DisableGirders",@"image",nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Disable Land Objects",@""),@"title",
                      NSLocalizedString(@"Disable land objects when generating maps",@""),@"description",
                      @"DisableLandObjects",@"image",nil],
                     nil];
    self.gameModifierArray = mods;
    [mods release];
    
    NSArray *basicSettings = [[NSArray alloc] initWithObjects:
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Damage Modifier",@""),@"title",@"Damage",@"image",
                               [NSNumber numberWithInt:100],@"default",[NSNumber numberWithInt:10],@"min",[NSNumber numberWithInt:300],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Turn Time",@""),@"title",@"Time",@"image",
                               [NSNumber numberWithInt:45],@"default",[NSNumber numberWithInt:1],@"min",[NSNumber numberWithInt:99],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Initial Health",@""),@"title",@"Health",@"image",
                               [NSNumber numberWithInt:100],@"default",[NSNumber numberWithInt:50],@"min",[NSNumber numberWithInt:200],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sudden Death Timeout",@""),@"title",@"SuddenDeath",@"image",
                               [NSNumber numberWithInt:15],@"default",[NSNumber numberWithInt:0],@"min",[NSNumber numberWithInt:50],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Crate Drops",@""),@"title",@"Box",@"image",
                               [NSNumber numberWithInt:5],@"default",[NSNumber numberWithInt:0],@"min",[NSNumber numberWithInt:9],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Mines Time",@""),@"title",@"Time",@"image",
                               [NSNumber numberWithInt:3],@"default",[NSNumber numberWithInt:0],@"min",[NSNumber numberWithInt:3],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Mines Number",@""),@"title",@"Mine",@"image",
                               [NSNumber numberWithInt:4],@"default",[NSNumber numberWithInt:1],@"min",[NSNumber numberWithInt:80],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Dud Mines Probability",@""),@"title",@"Dud",@"image",
                               [NSNumber numberWithInt:0],@"default",[NSNumber numberWithInt:0],@"min",[NSNumber numberWithInt:100],@"max",nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Explosives",@""),@"title",@"Damage",@"image",
                               [NSNumber numberWithInt:2],@"default",[NSNumber numberWithInt:0],@"min",[NSNumber numberWithInt:40],@"max",nil],
                              nil];
    self.basicSettingList = basicSettings;
    [basicSettings release];
}

// load from file
-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.title];
    NSMutableArray *scheme = [[NSMutableArray alloc] initWithContentsOfFile:schemeFile];
    self.schemeArray = scheme;
    [scheme release];
    [schemeFile release];
    
    [self.tableView reloadData];
}

// save to file
-(void) viewWillDisappear:(BOOL) animated {
    [super viewWillDisappear:animated];
    
    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.title];
    [self.schemeArray writeToFile:schemeFile atomically:YES];
    [schemeFile release];
}

#pragma mark -
#pragma mark textfield methods
-(void) cancel:(id) sender {
    if (textFieldBeingEdited != nil)
        [self.textFieldBeingEdited resignFirstResponder];
}

// set the new value
-(BOOL) save:(id) sender {    
    if (textFieldBeingEdited != nil) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.title] error:NULL];
        self.title = self.textFieldBeingEdited.text;
        [self.schemeArray writeToFile:[NSString stringWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.title] atomically:YES];
        [self.textFieldBeingEdited resignFirstResponder];
        return YES;
    }
    return NO;
}

// the textfield is being modified, update the navigation controller
-(void) textFieldDidBeginEditing:(UITextField *)aTextField{   
    self.textFieldBeingEdited = aTextField;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",@"from schemes table")
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",@"from schemes table")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
}

// the textfield has been modified, check for empty strings and restore original navigation bar
-(void) textFieldDidEndEditing:(UITextField *)aTextField{
    if ([textFieldBeingEdited.text length] == 0) 
        textFieldBeingEdited.text = [NSString stringWithFormat:@"New Scheme"];

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
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return [self.basicSettingList count];
            break;
        case 2:
            return [self.gameModifierArray count];
        default:
            break;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";
    static NSString *CellIdentifier2 = @"Cell2";
    
    UITableViewCell *cell = nil;
    NSInteger row = [indexPath row];
    
    switch ([indexPath section]) {
        case 0:
            cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
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
            
            for (UIView *oneView in cell.contentView.subviews) {
                if ([oneView isMemberOfClass:[UITextField class]]) {
                    // we find the uitextfied and we'll use its tag to understand which one is being edited
                    UITextField *textFieldFound = (UITextField *)oneView;
                    textFieldFound.text = self.title;
                }
            }
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            break;
        case 1:
            cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier1];
            NSDictionary *detail = [self.basicSettingList objectAtIndex:row];
            // need to offset this section (see format in CommodityFunctions.m and above)
            NSInteger gmSize = [self.gameModifierArray count];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
                                               reuseIdentifier:CellIdentifier1] autorelease];
                UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(260, 12, 150, 23)];
                slider.maximumValue = [[detail objectForKey:@"max"] floatValue];
                slider.minimumValue = [[detail objectForKey:@"min"] floatValue];
                slider.tag = row+gmSize;
                [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
                [cell.contentView addSubview:slider];
                [slider release];
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 7, 200, 30)];
                label.tag = LABEL_TAG;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
                [cell.contentView addSubview:label];
                [label release];
            }
            
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/icon%@.png",BTN_DIRECTORY(),[[self.basicSettingList objectAtIndex:row] objectForKey:@"image"]]];
            cell.imageView.image = [img scaleToSize:CGSizeMake(40, 40)];
            [img release];
            
            UILabel *cellLabel = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
            cellLabel.text = [[self.basicSettingList objectAtIndex:row] objectForKey:@"title"];
            
            UISlider *cellSlider = (UISlider *)[cell.contentView viewWithTag:row+gmSize];
            cellSlider.value = [[self.schemeArray objectAtIndex:row+gmSize] floatValue];
            
            // forced to use this weird format otherwise the label disappears when size of the text is bigger than the original
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.3d",[[self.schemeArray objectAtIndex:row+gmSize] intValue]];
            break;
        case 2:
            cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                               reuseIdentifier:CellIdentifier2] autorelease];
                UISwitch *onOff = [[UISwitch alloc] init];
                onOff.tag = row;
                [onOff addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = onOff;
                [onOff release];
            }
            
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/btn%@.png",BTN_DIRECTORY(),[[self.gameModifierArray objectAtIndex:row] objectForKey:@"image"]]];
            cell.imageView.image = image;
            [image release];
            [cell.imageView.layer setCornerRadius:7.0f];
            [cell.imageView.layer setBorderWidth:1];
            [cell.imageView.layer setMasksToBounds:YES];
            cell.textLabel.text = [[self.gameModifierArray objectAtIndex:row] objectForKey:@"title"];
            cell.detailTextLabel.text = [[self.gameModifierArray objectAtIndex:row] objectForKey:@"description"];
            [(UISwitch *)cell.accessoryView setOn:[[self.schemeArray objectAtIndex:row] boolValue] animated:NO];
        }
    
    return cell;
}

-(void) toggleSwitch:(id) sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    [self.schemeArray replaceObjectAtIndex:theSwitch.tag withObject:[NSNumber numberWithBool:theSwitch.on]];
}

-(void) sliderChanged:(id) sender {
    // need to offset this section (see format in CommodityFunctions.m and above)
    NSInteger gmSize = [self.gameModifierArray count];
    // the slider that changed is sent as object
    UISlider *theSlider = (UISlider *)sender;
    // create the indexPath of the row of the slider
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:theSlider.tag-gmSize inSection:1];
    // get its cell
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    // grab the associated label
    UILabel *label = (UILabel *)cell.detailTextLabel;
    // modify it
    label.text = [NSString stringWithFormat:@"%0.3d",(int)theSlider.value];
    // save changes in the main array (remember that you need to offset it)
    [self.schemeArray replaceObjectAtIndex:theSlider.tag withObject:[NSNumber numberWithInt:(int)theSlider.value]];
    NSLog(@"%@",self.schemeArray);
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
    UISwitch *sw = nil;
    UISlider *cellSlider = nil;
    
    switch ([indexPath section]) {
        case 0:
            for (UIView *oneView in cell.contentView.subviews) {
                if ([oneView isMemberOfClass:[UITextField class]]) {
                    textFieldBeingEdited = (UITextField *)oneView;
                    [textFieldBeingEdited becomeFirstResponder];
                }
            }
            break;
        case 1:
            cellSlider = (UISlider *)[cell.contentView viewWithTag:[indexPath row]+[self.gameModifierArray count]];
            [cellSlider setValue:[[[self.basicSettingList objectAtIndex:[indexPath row]] objectForKey:@"default"] floatValue] animated:YES];
            [self sliderChanged:cellSlider];
            //cell.detailTextLabel.text = [[[self.basicSettingList objectAtIndex:[indexPath row]] objectForKey:@"default"] stringValue];
            break;
        case 2:
            sw = (UISwitch *)cell.accessoryView;
            [sw setOn:!sw.on animated:YES];
            [self toggleSwitch:sw];
            break;
        default:
            break;
    }
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.textFieldBeingEdited = nil;
    self.schemeArray = nil;
    self.basicSettingList = nil;
    self.gameModifierArray = nil;
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}

-(void) dealloc {
    [textFieldBeingEdited release];
    [schemeArray release];
    [basicSettingList release];
    [gameModifierArray release];
    [super dealloc];
}


@end

