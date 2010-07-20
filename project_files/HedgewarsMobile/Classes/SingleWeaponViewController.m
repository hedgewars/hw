//
//  SingleWeaponViewController.m
//  Hedgewars
//
//  Created by Vittorio on 19/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SingleWeaponViewController.h"
#import "WeaponCellView.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

@implementation SingleWeaponViewController
@synthesize weaponName, ammoStoreImage, ammoNames;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];
    
    NSArray *array = [[NSArray alloc] initWithObjects:
                      NSLocalizedString(@"Grenade",@""),
                      NSLocalizedString(@"Cluster Bomb",@""),
                      NSLocalizedString(@"Bazooka",@""),
                      NSLocalizedString(@"Homing Bee",@""),
                      NSLocalizedString(@"Shotgun",@""),
                      NSLocalizedString(@"Pick Hammer",@""),
                      NSLocalizedString(@"Skip",@""),
                      NSLocalizedString(@"Rope",@""),
                      NSLocalizedString(@"Mine",@""),
                      NSLocalizedString(@"Deagle",@""),
                      NSLocalizedString(@"Dynamite",@""),
                      NSLocalizedString(@"Fire Punch",@""),
                      NSLocalizedString(@"Slash",@""),
                      NSLocalizedString(@"Baseball bat",@""),
                      NSLocalizedString(@"Parachute",@""),
                      NSLocalizedString(@"Air Attack",@""),
                      NSLocalizedString(@"Mines Attack",@""),
                      NSLocalizedString(@"Blow Torch",@""),
                      NSLocalizedString(@"Construction",@""),
                      NSLocalizedString(@"Teleport",@""),
                      NSLocalizedString(@"Switch Hedgehog",@""),
                      NSLocalizedString(@"Mortar",@""),
                      NSLocalizedString(@"Kamikaze",@""),
                      NSLocalizedString(@"Cake",@""),
                      NSLocalizedString(@"Seduction",@""),
                      NSLocalizedString(@"Watermelon Bomb",@""),
                      NSLocalizedString(@"Hellish Hand Grenade",@""),
                      NSLocalizedString(@"Napalm Attack",@""),
                      NSLocalizedString(@"Drill Rocket",@""),
                      NSLocalizedString(@"Ballgun",@""),
                      NSLocalizedString(@"RC Plane",@""),
                      NSLocalizedString(@"Low Gravity",@""),
                      NSLocalizedString(@"Extra Damage",@""),
                      NSLocalizedString(@"Invulnerable",@""),
                      NSLocalizedString(@"Extra Time",@""),
                      NSLocalizedString(@"Laser Sight",@""),
                      NSLocalizedString(@"Vampirism",@""),
                      NSLocalizedString(@"Sniper Rifle",@""),
                      NSLocalizedString(@"Flying Saucer",@""),
                      NSLocalizedString(@"Molotov Cocktail",@""),
                      NSLocalizedString(@"Birdy",@""),
                      NSLocalizedString(@"Portable Portal Device",@""),
                      NSLocalizedString(@"Piano Attack",@""),
                      NSLocalizedString(@"Old Limburger",@""),
                      NSLocalizedString(@"Sine Gun",@""),
                      NSLocalizedString(@"Flamethrower",@""),
                      nil];
    self.ammoNames = array;
    [array release];

    quantity = (char *)malloc(sizeof(char)*(CURRENT_AMMOSIZE+1));
    probability = (char *)malloc(sizeof(char)*(CURRENT_AMMOSIZE+1));
    delay = (char *)malloc(sizeof(char)*(CURRENT_AMMOSIZE+1));
    crateness = (char *)malloc(sizeof(char)*(CURRENT_AMMOSIZE+1));
    
    NSString *str = [NSString stringWithFormat:@"%@/AmmoMenu/Ammos.png",GRAPHICS_DIRECTORY()];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:str];
    self.ammoStoreImage = img;
    [img release];
    
    self.title = NSLocalizedString(@"Edit weapons preferences",@"");
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    NSString *ammoFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",WEAPONS_DIRECTORY(),self.weaponName];
    NSDictionary *weapon = [[NSDictionary alloc] initWithContentsOfFile:ammoFile];
    [ammoFile release];
    
    const char *tmp1 = [[weapon objectForKey:@"ammostore_initialqt"] UTF8String];
    const char *tmp2 = [[weapon objectForKey:@"ammostore_probability"] UTF8String];
    const char *tmp3 = [[weapon objectForKey:@"ammostore_delay"] UTF8String];
    const char *tmp4 = [[weapon objectForKey:@"ammostore_crate"] UTF8String];
    [weapon release];
    
    // if the new weaponset is diffrent from the older we need to update it replacing
    // the missing ammos with 0 quantity
    int oldlen = strlen(tmp1);
    for (int i = 0; i < oldlen; i++) {
        quantity[i] = tmp1[i];
        probability[i] = tmp2[i];
        delay[i] = tmp3[i];
        crateness[i] = tmp4[i];
    }
    for (int i = oldlen; i < CURRENT_AMMOSIZE; i++) {
        quantity[i] = '0';
        probability[i] = '0';
        delay[i] = '0';
        crateness[i] = '0';
    }
    
    [self.tableView reloadData];
}

-(void) viewWillDisappear:(BOOL) animated {
    [super viewWillDisappear:animated];
    [self saveAmmos];
}

-(void) saveAmmos {
    quantity[CURRENT_AMMOSIZE] = '\0';
    probability[CURRENT_AMMOSIZE] = '\0';
    delay[CURRENT_AMMOSIZE] = '\0';
    crateness[CURRENT_AMMOSIZE] = '\0';
    
    NSString *quantityStr = [NSString stringWithUTF8String:quantity];
    NSString *probabilityStr = [NSString stringWithUTF8String:probability];
    NSString *delayStr = [NSString stringWithUTF8String:delay];
    NSString *cratenessStr = [NSString stringWithUTF8String:crateness];

    NSDictionary *weapon = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithInt:CURRENT_AMMOSIZE],@"version",
                            quantityStr,@"ammostore_initialqt",
                            probabilityStr,@"ammostore_probability",
                            delayStr,@"ammostore_delay",
                            cratenessStr,@"ammostore_crate", nil];

    NSString *ammoFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",WEAPONS_DIRECTORY(),self.weaponName];
    [weapon writeToFile:ammoFile atomically:YES];
    [ammoFile release];
    [weapon release];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 1;
    else
        return CURRENT_AMMOSIZE;
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";
    NSInteger row = [indexPath row];
    UITableViewCell *cell = nil;

    if (0 == [indexPath section]) {
        EditableCellView *customCell = (EditableCellView *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
        if (customCell == nil) {
            customCell = [[[EditableCellView alloc] initWithStyle:UITableViewCellStyleDefault 
                                            reuseIdentifier:CellIdentifier0] autorelease];
            customCell.delegate = self;
        }
        
        customCell.textField.text = self.weaponName;
        customCell.detailTextLabel.text = nil;
        customCell.imageView.image = nil;
        customCell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell = customCell;
    } else {
        WeaponCellView *customCell = (WeaponCellView *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (customCell == nil) {
            customCell = [[[WeaponCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
            customCell.delegate = self;
        }
        
        int x = ((row*32)/1024)*32;
        int y = (row*32)%1024;
        
        UIImage *img = [[self.ammoStoreImage cutAt:CGRectMake(x, y, 32, 32)] makeRoundCornersOfSize:CGSizeMake(7, 7)];
        customCell.weaponIcon.image = img;
        customCell.weaponName.text = [ammoNames objectAtIndex:row];
        customCell.tag = row;
        
        [customCell.initialQt setValue:[[NSString stringWithFormat:@"%c",quantity[row]] intValue] animated:NO];
        [customCell.probabilityQt setValue:[[NSString stringWithFormat:@"%c", probability[row]] intValue] animated:NO];
        [customCell.delayQt setValue:[[NSString stringWithFormat:@"%c", delay[row]] intValue] animated:NO];
        [customCell.crateQt setValue:[[NSString stringWithFormat:@"%c", crateness[row]] intValue] animated:NO];
        cell = customCell;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat) tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == [indexPath section])
        return aTableView.rowHeight;
    else
        return 120;
}

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == [indexPath section]) {
        EditableCellView *editableCell = (EditableCellView *)[aTableView cellForRowAtIndexPath:indexPath];
        [editableCell replyKeyboard];
    }
}

#pragma mark -
#pragma mark editableCellView delegate
// set the new value
-(void) saveTextFieldValue:(NSString *)textString {    
    // delete old file
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist",WEAPONS_DIRECTORY(),self.weaponName] error:NULL];
    // update filename
    self.weaponName = textString;
    // save new file
    [self saveAmmos];
}

#pragma mark -
#pragma mark WeaponButtonControllerDelegate
-(void) updateValues:(NSArray *)withArray atIndex:(NSInteger) index {
    quantity[index] = [[NSString stringWithFormat:@"%d",[[withArray objectAtIndex:0] intValue]] characterAtIndex:0];
    probability[index] = [[NSString stringWithFormat:@"%d",[[withArray objectAtIndex:1] intValue]] characterAtIndex:0];
    delay[index] = [[NSString stringWithFormat:@"%d",[[withArray objectAtIndex:2] intValue]] characterAtIndex:0];
    crateness[index] = [[NSString stringWithFormat:@"%d",[[withArray objectAtIndex:3] intValue]] characterAtIndex:0];
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    free(quantity); quantity = NULL;
    free(probability); probability = NULL;
    free(delay); delay = NULL;
    free(crateness); crateness = NULL;
    [super viewDidUnload];
    self.weaponName = nil;
    self.ammoStoreImage = nil;
    self.ammoNames = nil;
    MSG_DIDUNLOAD();
}


-(void) dealloc {
    [weaponName release];
    [ammoStoreImage release];
    [ammoNames release];
    [super dealloc];
}


@end

