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
#define SWITCH_TAG 67890

@implementation SingleSchemeViewController
@synthesize schemeName, schemeDictionary, basicSettingList, gameModifierArray;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];

    // title, description, image name (+btn)
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
                     [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"AI Survival Mode",@""),@"title",
                      NSLocalizedString(@"AI-controlled hogs respawn on death",@""),@"description",
                      @"AISurvival",@"image",nil],
                     nil];
    self.gameModifierArray = mods;
    [mods release];

    // title, image name (+icon), default value, max value, min value
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

    self.title = NSLocalizedString(@"Edit scheme preferences",@"");
}

// load from file
-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];

    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.schemeName];
    NSMutableDictionary *scheme = [[NSMutableDictionary alloc] initWithContentsOfFile:schemeFile];
    [schemeFile release];
    self.schemeDictionary = scheme;
    [scheme release];

    [self.tableView reloadData];
}

// save to file
-(void) viewWillDisappear:(BOOL) animated {
    [super viewWillDisappear:animated];

    NSString *schemeFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.schemeName];
    [self.schemeDictionary writeToFile:schemeFile atomically:YES];
    [schemeFile release];
}

#pragma mark -
#pragma mark editableCellView delegate
// set the new value
-(void) saveTextFieldValue:(NSString *)textString withTag:(NSInteger) tagValue {
    if (tagValue == 0) {
        // delete old file
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.schemeName] error:NULL];
        // update filename
        self.schemeName = textString;
        // save new file
        [self.schemeDictionary writeToFile:[NSString stringWithFormat:@"%@/%@.plist",SCHEMES_DIRECTORY(),self.schemeName] atomically:YES];
    } else {
        [self.schemeDictionary setObject:textString forKey:@"description"];
    }
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
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
    EditableCellView *editableCell = nil;
    NSInteger row = [indexPath row];

    switch ([indexPath section]) {
        case 0:
            editableCell = (EditableCellView *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
            if (editableCell == nil) {
                editableCell = [[[EditableCellView alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:CellIdentifier0] autorelease];
                editableCell.delegate = self;
            }
            editableCell.tag = row;
            editableCell.selectionStyle = UITableViewCellSelectionStyleNone;
            editableCell.imageView.image = nil;
            editableCell.detailTextLabel.text = nil;
         
            if (row == 0) {
                editableCell.textField.text = self.schemeName;
            } else {
                editableCell.minimumCharacters = 0;
                editableCell.textField.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
                editableCell.textField.text = [self.schemeDictionary objectForKey:@"description"];
                editableCell.textField.placeholder = NSLocalizedString(@"You can add a description if you wish",@"");
            }
            cell = editableCell;
            break;
        case 1:
            cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier1];
            NSDictionary *detail = [self.basicSettingList objectAtIndex:row];
            // need to offset this section (see format in CommodityFunctions.m and above)
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                               reuseIdentifier:CellIdentifier1] autorelease];

                int offset = 0;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    offset = 50;

                UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(offset+260, 12, offset+150, 23)];
                slider.maximumValue = [[detail objectForKey:@"max"] floatValue];
                slider.minimumValue = [[detail objectForKey:@"min"] floatValue];
                slider.tag = SLIDER_TAG+row;
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
            cell.imageView.image = img;
            [img release];

            UILabel *cellLabel = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
            cellLabel.text = [[self.basicSettingList objectAtIndex:row] objectForKey:@"title"];

            UISlider *cellSlider = (UISlider *)[cell.contentView viewWithTag:SLIDER_TAG+row];
            cellSlider.value = [[[self.schemeDictionary objectForKey:@"basic"] objectAtIndex:row] floatValue];

            // forced to use this weird format otherwise the label disappears when size of the text is bigger than the original
            NSString *prestring = [NSString stringWithFormat:@"%d",(NSInteger) cellSlider.value];
            while ([prestring length] <= 4)
                prestring = [NSString stringWithFormat:@" %@",prestring];
            cell.detailTextLabel.text = prestring;

            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        case 2:
            cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                               reuseIdentifier:CellIdentifier2] autorelease];
                UISwitch *onOff = [[UISwitch alloc] init];
                onOff.tag = SWITCH_TAG+row;
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
            [(UISwitch *)cell.accessoryView setOn:[[[self.schemeDictionary objectForKey:@"gamemod"] objectAtIndex:row] boolValue] animated:NO];

            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

    return cell;
}

-(void) toggleSwitch:(id) sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    NSMutableArray *array = [self.schemeDictionary objectForKey:@"gamemod"];
    [array replaceObjectAtIndex:theSwitch.tag-SWITCH_TAG withObject:[NSNumber numberWithBool:theSwitch.on]];
}

-(void) sliderChanged:(id) sender {
    // the slider that changed is sent as object
    UISlider *theSlider = (UISlider *)sender;
    // create the indexPath of the row of the slider
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:theSlider.tag-SLIDER_TAG inSection:1];
    // get its cell
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    // grab the associated label
    UILabel *label = (UILabel *)cell.detailTextLabel;
    // modify it
    label.text = [NSString stringWithFormat:@"%d",(NSInteger) theSlider.value];
    // save changes in the main array
    NSMutableArray *array = [self.schemeDictionary objectForKey:@"basic"];
    [array replaceObjectAtIndex:theSlider.tag-SLIDER_TAG withObject:[NSNumber numberWithInt:(NSInteger) theSlider.value]];
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
    EditableCellView *editableCell = nil;
    UISlider *cellSlider = nil;

    switch ([indexPath section]) {
        case 0:
            editableCell = (EditableCellView *)cell;
            [editableCell replyKeyboard];
            break;
        case 1:
            cellSlider = (UISlider *)[cell.contentView viewWithTag:[indexPath row]+SLIDER_TAG];
            [cellSlider setValue:[[[self.basicSettingList objectAtIndex:[indexPath row]] objectForKey:@"default"] floatValue] animated:YES];
            [self sliderChanged:cellSlider];
            //cell.detailTextLabel.text = [[[self.basicSettingList objectAtIndex:[indexPath row]] objectForKey:@"default"] stringValue];
            break;
        case 2:
            /*sw = (UISwitch *)cell.accessoryView;
            [sw setOn:!sw.on animated:YES];
            [self toggleSwitch:sw];*/
            break;
        default:
            break;
    }

    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = NSLocalizedString(@"Scheme Name", @"");
            break;
        case 1:
            sectionTitle = NSLocalizedString(@"Game Settings", @"");
            break;
        case 2:
            sectionTitle = NSLocalizedString(@"Game Modifiers", @"");
            break;
        default:
            DLog(@"nope");
            break;
    }
    return sectionTitle;
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.basicSettingList = nil;
    self.gameModifierArray = nil;
}

-(void) viewDidUnload {
    self.schemeName = nil;
    self.schemeDictionary = nil;
    self.basicSettingList = nil;
    self.gameModifierArray = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [schemeName release];
    [schemeDictionary release];
    [basicSettingList release];
    [gameModifierArray release];
    [super dealloc];
}

@end
