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

- (void)updateValues:(NSArray *)withArray atIndex:(NSInteger)index;

@end

@interface WeaponCellView : UITableViewCell {
    id<WeaponButtonControllerDelegate> __weak delegate;
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

@property (nonatomic, weak) id<WeaponButtonControllerDelegate> delegate;

@property (nonatomic, strong) UILabel *weaponName;
@property (nonatomic, strong) UIImageView *weaponIcon;

@property (nonatomic, strong) UISlider *initialSli;
@property (nonatomic, strong) UISlider *probabilitySli;
@property (nonatomic, strong) UISlider *delaySli;
@property (nonatomic, strong) UISlider *crateSli;

@property (nonatomic, strong) UIImageView *initialImg;
@property (nonatomic, strong) UIImageView *probabilityImg;
@property (nonatomic, strong) UIImageView *delayImg;
@property (nonatomic, strong) UIImageView *crateImg;

@property (nonatomic, strong) UILabel *initialLab;
@property (nonatomic, strong) UILabel *probabilityLab;
@property (nonatomic, strong) UILabel *delayLab;
@property (nonatomic, strong) UILabel *crateLab;

@property (nonatomic, strong) UILabel *helpLabel;

@end
