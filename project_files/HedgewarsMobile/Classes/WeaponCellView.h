//
//  WeaponCellView.h
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WeaponButtonControllerDelegate <NSObject>

-(void) valueChanged:(id) sender;

@end

@interface WeaponCellView : UITableViewCell {
    id<WeaponButtonControllerDelegate> delegate;
    UILabel *weaponName;
    UIImageView *weaponIcon;
    
    UISlider *initialQt;
    UISlider *probabilityQt;
    UISlider *delayQt;
    UISlider *crateQt;
    
@private
    UIImageView *initialImg;
    UIImageView *probabImg;
    UIImageView *delayImg;
    UIImageView *crateImg;
    
    UILabel *initialLab;
    UILabel *probLab;
    UILabel *delLab;
    UILabel *craLab;
}

@property (nonatomic,assign) id<WeaponButtonControllerDelegate> delegate;

@property (nonatomic,retain) UILabel *weaponName;
@property (nonatomic,retain) UIImageView *weaponIcon;
    
@property (nonatomic,retain) UISlider *initialQt;
@property (nonatomic,retain) UISlider *probabilityQt;
@property (nonatomic,retain) UISlider *delayQt;
@property (nonatomic,retain) UISlider *crateQt;

@property (nonatomic,retain) UIImageView *initialImg;
@property (nonatomic,retain) UIImageView *probabImg;
@property (nonatomic,retain) UIImageView *delayImg;
@property (nonatomic,retain) UIImageView *crateImg;

@property (nonatomic,retain) UILabel *initialLab;
@property (nonatomic,retain) UILabel *probLab;
@property (nonatomic,retain) UILabel *delLab;
@property (nonatomic,retain) UILabel *craLab;

@end
