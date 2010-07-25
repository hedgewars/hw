//
//  WeaponCellView.m
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WeaponCellView.h"
#import "CommodityFunctions.h"

@implementation WeaponCellView
@synthesize delegate, weaponName, weaponIcon, initialQt, probabilityQt, delayQt, crateQt,
            initialImg, probabImg, delayImg, crateImg, initialLab, probLab, delLab, craLab;

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        delegate = nil;
        
        weaponName = [[UILabel alloc] init];
        weaponName.backgroundColor = [UIColor clearColor];
        weaponName.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        weaponIcon = [[UIImageView alloc] init];
    
        initialQt = [[UISlider alloc] init];
        [initialQt addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        initialQt.maximumValue = 9;
        initialQt.minimumValue = 0;
        
        probabilityQt = [[UISlider alloc] init];
        [probabilityQt addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        probabilityQt.maximumValue = 9;
        probabilityQt.minimumValue = 0;
        
        delayQt = [[UISlider alloc] init];
        [delayQt addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        delayQt.maximumValue = 9;
        delayQt.minimumValue = 0;
        
        crateQt = [[UISlider alloc] init];
        [crateQt addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        crateQt.maximumValue = 9;
        crateQt.minimumValue = 0;
    
        NSString *imgAmmoStr = [NSString stringWithFormat:@"%@/iconAmmo.png",BTN_DIRECTORY()];
        NSString *imgDamageStr = [NSString stringWithFormat:@"%@/iconDamage.png",BTN_DIRECTORY()];
        NSString *imgTimeStr = [NSString stringWithFormat:@"%@/iconTime.png",BTN_DIRECTORY()];
        NSString *imgBoxStr = [NSString stringWithFormat:@"%@/iconBox.png",BTN_DIRECTORY()];

        initialImg = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imgAmmoStr]];
        probabImg = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imgDamageStr]];
        delayImg = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imgTimeStr]];
        crateImg = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imgBoxStr]];
        
        initialLab = [[UILabel alloc] init];
        initialLab.backgroundColor = [UIColor clearColor];
        initialLab.textColor = [UIColor grayColor];
        initialLab.textAlignment = UITextAlignmentCenter;
        
        probLab = [[UILabel alloc] init];
        probLab.backgroundColor = [UIColor clearColor];
        probLab.textColor = [UIColor grayColor];
        probLab.textAlignment = UITextAlignmentCenter;
        
        delLab = [[UILabel alloc] init];
        delLab.backgroundColor = [UIColor clearColor];
        delLab.textColor = [UIColor grayColor];
        delLab.textAlignment = UITextAlignmentCenter;
        
        craLab = [[UILabel alloc] init];
        craLab.backgroundColor = [UIColor clearColor];
        craLab.textColor = [UIColor grayColor];
        craLab.textAlignment = UITextAlignmentCenter;
        
        [self.contentView addSubview:weaponName]; // [weaponName release];
        [self.contentView addSubview:weaponIcon]; // [weaponIcon release];
        
        [self.contentView addSubview:initialQt];  // [initialQt release];
        [self.contentView addSubview:probabilityQt]; // [probabilityQt release];
        [self.contentView addSubview:delayQt];    // [delayQt release];
        [self.contentView addSubview:crateQt];    // [crateQt release];
        
        [self.contentView addSubview:initialImg]; // [initialImg release];
        [self.contentView addSubview:probabImg];  // [probabImg release];
        [self.contentView addSubview:delayImg];   // [delayImg release];
        [self.contentView addSubview:crateImg];   // [crateImg release];

        [self.contentView addSubview:initialLab]; // [initialLab release];
        [self.contentView addSubview:probLab];    // [probLab release];
        [self.contentView addSubview:delLab];     // [delLab release];
        [self.contentView addSubview:craLab];     // [craLab release];
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];

    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        boundsX += 65;
    else
        boundsX -= 9;

    weaponIcon.frame = CGRectMake(5, 5, 32, 32);
    weaponName.frame = CGRectMake(45, 8, 200, 25);
    
    // second line
    initialImg.frame = CGRectMake(boundsX+20, 40, 32, 32);
    initialLab.frame = CGRectMake(boundsX+56, 40, 20, 32);
    initialLab.text = ((int)initialQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)initialQt.value];
    initialQt.frame = CGRectMake(boundsX+80, 40, 150, 32);
    
    probabImg.frame = CGRectMake(boundsX+255, 40, 32, 32);
    probLab.frame = CGRectMake(boundsX+291, 40, 20, 32);
    probLab.text = ((int)probabilityQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)probabilityQt.value];
    probabilityQt.frame = CGRectMake(boundsX+314, 40, 150, 32);
    
    // third line
    delayImg.frame = CGRectMake(boundsX+20, 80, 32, 32);
    delLab.frame = CGRectMake(boundsX+56, 80, 20, 32);
    delLab.text = ((int)delayQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)delayQt.value];
    delayQt.frame = CGRectMake(boundsX+80, 80, 150, 32);
    
    crateImg.frame = CGRectMake(boundsX+255, 80, 32, 32);
    craLab.frame = CGRectMake(boundsX+291, 80, 20, 32);
    craLab.text = ((int)crateQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)crateQt.value];
    crateQt.frame = CGRectMake(boundsX+314, 80, 150, 32);
}

/*
-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}
*/

-(void) valueChanged:(id) sender {
    if (self.delegate != nil) {
        initialLab.text = ((int)initialQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)initialQt.value];
        probLab.text = ((int)probabilityQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)probabilityQt.value];
        delLab.text = ((int)delayQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)delayQt.value];
        craLab.text = ((int)crateQt.value == 9) ? @"∞" : [NSString stringWithFormat:@"%d",(int)crateQt.value];
        
        [delegate updateValues:[NSArray arrayWithObjects:
                                [NSNumber numberWithInt:(int)initialQt.value],
                                [NSNumber numberWithInt:(int)probabilityQt.value],
                                [NSNumber numberWithInt:(int)delayQt.value],
                                [NSNumber numberWithInt:(int)crateQt.value], nil] 
                       atIndex:self.tag];
    } else
        DLog(@"error - delegate = nil!");
}

-(void) dealloc {
    self.delegate = nil;
    releaseAndNil(weaponName);
    releaseAndNil(weaponIcon);
    releaseAndNil(initialQt);
    releaseAndNil(probabilityQt);
    releaseAndNil(delayQt);
    releaseAndNil(crateQt);
    releaseAndNil(initialImg);
    releaseAndNil(probabImg);
    releaseAndNil(delayImg);
    releaseAndNil(crateImg);
    releaseAndNil(initialLab);
    releaseAndNil(probLab);
    releaseAndNil(delLab);
    releaseAndNil(craLab);
    [super dealloc];
}

@end
