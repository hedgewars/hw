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
@synthesize delegate, weaponName, weaponIcon, initialQt, probability, delay, crateQt;

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        delegate = nil;
        
        weaponName = [[UILabel alloc] init];
        weaponName.backgroundColor = [UIColor clearColor];
        weaponName.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        weaponIcon = [[UIImageView alloc] init];
    
        NSString *imgStr;
        initialQt = [[UIButton alloc] init];
        imgStr = [NSString stringWithFormat:@"%@/iconAmmo.png",BTN_DIRECTORY()];
        [initialQt setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [initialQt setBackgroundImage:[UIImage imageWithContentsOfFile:imgStr] forState:UIControlStateNormal];
        [initialQt addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        probability = [[UIButton alloc] init];
        imgStr = [NSString stringWithFormat:@"%@/iconDamage.png",BTN_DIRECTORY()];
        [probability setBackgroundImage:[UIImage imageWithContentsOfFile:imgStr] forState:UIControlStateNormal];
        [probability addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

        delay = [[UIButton alloc] init];
        imgStr = [NSString stringWithFormat:@"%@/iconTime.png",BTN_DIRECTORY()];
        [delay setBackgroundImage:[UIImage imageWithContentsOfFile:imgStr] forState:UIControlStateNormal];
        [delay addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

        crateQt = [[UIButton alloc] init];
        imgStr = [NSString stringWithFormat:@"%@/iconBox.png",BTN_DIRECTORY()];
        [crateQt setBackgroundImage:[UIImage imageWithContentsOfFile:imgStr] forState:UIControlStateNormal];
        [crateQt addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

        [self.contentView addSubview:weaponName];
        [self.contentView addSubview:weaponIcon];
        [self.contentView addSubview:initialQt];
        [self.contentView addSubview:probability];
        [self.contentView addSubview:delay];
        [self.contentView addSubview:crateQt];
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];

    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    CGRect frame;
    
    frame = CGRectMake(boundsX+5, 5, 32, 32);
    weaponIcon.frame = frame;

    frame = CGRectMake(boundsX+45, 8, 200, 25);
    weaponName.frame = frame;
    
    // second line
    frame = CGRectMake(boundsX+20, 40, 32, 32);
    initialQt.frame = frame;
    
    frame = CGRectMake(boundsX+60, 40, 32, 32);
    probability.frame = frame;
    
    frame = CGRectMake(boundsX+100, 40, 32, 32);
    delay.frame = frame;
    
    frame = CGRectMake(boundsX+140, 40, 32, 32);
    crateQt.frame = frame;
}

/*
-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}
*/

-(void) buttonPressed:(id) sender {
    if (self.delegate != nil) {
        [(UIButton *)sender setTag:self.tag];
        [delegate buttonPressed:sender];
    } else
        DLog(@"error - delegate = nil!");
}

-(void) dealloc {
    [weaponName release];
    [weaponIcon release];
    [initialQt release];
    [probability release];
    [delay release];
    [crateQt release];
    [super dealloc];
}


@end
