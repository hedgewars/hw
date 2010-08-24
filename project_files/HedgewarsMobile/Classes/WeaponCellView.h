//
//  WeaponCellView.h
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WeaponButtonControllerDelegate <NSObject>

-(void) updateValues:(NSArray *)withArray atIndex:(NSInteger) index;

@end

@interface WeaponCellView : UITableViewCell {
    id<WeaponButtonControllerDelegate> delegate;
    UILabel *weaponName;
    UIImageView *weaponIcon;

    UISlider *initialSli;
    UISlider *probabilitySli;
    UISlider *delaySli;
    UISlider *crateSli;

@private
    UIImageView *initialImg;
    UIImageView *probabilityImg;
    UIImageView *delayImg;
    UIImageView *crateImg;

    UILabel *initialLab;
    UILabel *probabilityLab;
    UILabel *delayLab;
    UILabel *crateLab;

    UILabel *helpLabel;
}

@property (nonatomic,assign) id<WeaponButtonControllerDelegate> delegate;

@property (nonatomic,retain) UILabel *weaponName;
@property (nonatomic,retain) UIImageView *weaponIcon;

@property (nonatomic,retain) UISlider *initialSli;
@property (nonatomic,retain) UISlider *probabilitySli;
@property (nonatomic,retain) UISlider *delaySli;
@property (nonatomic,retain) UISlider *crateSli;

@property (nonatomic,retain) UIImageView *initialImg;
@property (nonatomic,retain) UIImageView *probabilityImg;
@property (nonatomic,retain) UIImageView *delayImg;
@property (nonatomic,retain) UIImageView *crateImg;

@property (nonatomic,retain) UILabel *initialLab;
@property (nonatomic,retain) UILabel *probabilityLab;
@property (nonatomic,retain) UILabel *delayLab;
@property (nonatomic,retain) UILabel *crateLab;

@property (nonatomic,retain) UILabel *helpLabel;

@end
