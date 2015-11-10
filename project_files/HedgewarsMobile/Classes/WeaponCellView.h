/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


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
