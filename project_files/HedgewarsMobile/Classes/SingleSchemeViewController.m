/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 23/05/2010.
 */


#import "SingleSchemeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

#define LABEL_TAG  12345
#define SLIDER_TAG 54321
#define SWITCH_TAG 67890

#define checkValueString(detailString,labelSting,sliderRef); \
    if ([labelSting isEqualToString:@"Turn Time"] && (NSInteger) sliderRef.value == 100) \
        detailString = @"∞"; \
    else if ([labelSting isEqualToString:@"Water Rise Amount"] && (NSInteger) sliderRef.value == 100) \
        detailString = NSLocalizedString(@"Nvr",@"Short for 'Never'"); \
    else if ([labelSting isEqualToString:@"Crate Drop Turns"] && (NSInteger) sliderRef.value == 0) \
        detailString = NSLocalizedString(@"Nvr",@"Short for 'Never'"); \
    else if ([labelSting isEqualToString:@"Mines Time"] && (NSInteger) sliderRef.value == -1) \
        detailString = NSLocalizedString(@"Rnd",@"Short for 'Random'"); \
    else \
        detailString = [NSString stringWithFormat:@"%d",(NSInteger) sliderRef.value];


@implementation SingleSchemeViewController
@synthesize schemeName, schemeDictionary, basicSettingList, gameModifierArray;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];
    NSString *path = nil;

    // title, description, image name (+btn)
    path = [NSString stringWithFormat:@"%@/gameFlags_en.plist",IFRONTEND_DIRECTORY()];
    NSArray *mods = [[NSArray alloc] initWithContentsOfFile:path];
    self.gameModifierArray = mods;
    [mods release];

    // title, image name (+icon), default value, max value, min value
    path = [NSString stringWithFormat:@"%@/basicFlags_en.plist",IFRONTEND_DIRECTORY()];
    NSArray *basicSettings = [[NSArray alloc] initWithContentsOfFile:path];
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
            return [[self.schemeDictionary objectForKey:@"basic"] count];
            break;
        case 2:
            return [[self.schemeDictionary objectForKey:@"gamemod"] count];
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
                editableCell.textField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
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
                if (IS_IPAD())
                    offset = 50;

                UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(offset+260, 12, offset+150, 23)];
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

            // can't use the viewWithTag method because row is dynamic
            UISlider *cellSlider = nil;
            for (UIView *oneView in cell.contentView.subviews) {
                if ([oneView isMemberOfClass:[UISlider class]]) {
                    cellSlider = (UISlider *)oneView;
                    break;
                } 
            }
            cellSlider.tag = SLIDER_TAG + row;
            cellSlider.maximumValue = [[detail objectForKey:@"max"] floatValue];
            cellSlider.minimumValue = [[detail objectForKey:@"min"] floatValue];
            cellSlider.value = [[[self.schemeDictionary objectForKey:@"basic"] objectAtIndex:row] floatValue];

            NSString *prestring = nil;
            checkValueString(prestring,cellLabel.text,cellSlider);

            // forced to use this weird format otherwise the label disappears when size of the text is bigger than the original
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
                [onOff addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = onOff;
                [onOff release];
            }

            UISwitch *switcher = (UISwitch *)cell.accessoryView;
            switcher.tag = SWITCH_TAG + row;
            [switcher setOn:[[[self.schemeDictionary objectForKey:@"gamemod"] objectAtIndex:row] boolValue] animated:NO];
            
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/btn%@.png",BTN_DIRECTORY(),[[self.gameModifierArray objectAtIndex:row] objectForKey:@"image"]]];
            cell.imageView.image = image;
            [image release];
            [cell.imageView.layer setCornerRadius:7.0f];
            [cell.imageView.layer setMasksToBounds:YES];
            cell.textLabel.text = [[self.gameModifierArray objectAtIndex:row] objectForKey:@"title"];
            cell.detailTextLabel.text = [[self.gameModifierArray objectAtIndex:row] objectForKey:@"description"];
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.minimumFontSize = 6;

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
    // grab the associated labels
    UILabel *detailLabel = (UILabel *)cell.detailTextLabel;
    UILabel *cellLabel = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
    // modify it

    checkValueString(detailLabel.text,cellLabel.text,theSlider);

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

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 2)
        return 56;
    else
        return self.tableView.rowHeight;
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
