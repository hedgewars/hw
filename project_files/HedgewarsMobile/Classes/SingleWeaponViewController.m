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
@synthesize ammoStoreImage, ammoNames;

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

    quantity = (char *)malloc(sizeof(char)*CURRENT_AMMOSIZE);
    probability = (char *)malloc(sizeof(char)*CURRENT_AMMOSIZE);
    delay = (char *)malloc(sizeof(char)*CURRENT_AMMOSIZE);
    crateness = (char *)malloc(sizeof(char)*CURRENT_AMMOSIZE);
    
    NSString *str = [NSString stringWithFormat:@"%@/AmmoMenu/Ammos.png",GRAPHICS_DIRECTORY()];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:str];
    self.ammoStoreImage = img;
    [img release];
    
    self.tableView.rowHeight = 75;
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    NSString *ammoFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",WEAPONS_DIRECTORY(),self.title];
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

    NSString *ammoFile = [[NSString alloc] initWithFormat:@"%@/%@.plist",WEAPONS_DIRECTORY(),self.title];
    [weapon writeToFile:ammoFile atomically:YES];
    [ammoFile release];
    [weapon release];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return CURRENT_AMMOSIZE;
}


// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = [indexPath row];
    
    WeaponCellView *cell = (WeaponCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[WeaponCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.delegate = self;
    }
    
    int x = ((row*32)/1024)*32;
    int y = (row*32)%1024;

    UIImage *img = [[self.ammoStoreImage cutAt:CGRectMake(x, y, 32, 32)] makeRoundCornersOfSize:CGSizeMake(7, 7)];
    cell.weaponIcon.image = img;
    cell.weaponName.text = [ammoNames objectAtIndex:row];
    cell.tag = row;
    
    [cell.initialQt setTitle:[NSString stringWithFormat:@"%c",quantity[row]] forState:UIControlStateNormal];
    cell.probability.titleLabel.text = [NSString stringWithFormat:@"%c",probability[row]];
    cell.delay.titleLabel.text = [NSString stringWithFormat:@"%c",delay[row]];
    cell.crateQt.titleLabel.text = [NSString stringWithFormat:@"%c",crateness[row]];
    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

#pragma mark -
#pragma mark WeaponButtonControllerDelegate
-(void) buttonPressed:(id) sender {
    UIButton *button = (UIButton *)sender;
    DLog(@"%@ %d", button.titleLabel.text, button.tag);
}

#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    free(quantity);
    free(probability);
    free(delay);
    free(crateness);
    [super viewDidUnload];
    MSG_DIDUNLOAD();
}


-(void) dealloc {
    [super dealloc];
}


@end

