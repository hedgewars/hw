//
//  WeaponCellView.h
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WeaponButtonControllerDelegate <NSObject>

-(void) buttonPressed:(id) sender;

@end

@interface WeaponCellView : UITableViewCell {
    id<WeaponButtonControllerDelegate> delegate;
    UILabel *weaponName;
    UIImageView *weaponIcon;
    
    UIButton *initialQt;
    UIButton *probability;
    UIButton *delay;
    UIButton *crateQt;
}

@property (nonatomic,assign) id<WeaponButtonControllerDelegate> delegate;

@property (nonatomic,retain) UILabel *weaponName;
@property (nonatomic,retain) UIImageView *weaponIcon;
    
@property (nonatomic,retain) UIButton *initialQt;
@property (nonatomic,retain) UIButton *probability;
@property (nonatomic,retain) UIButton *delay;
@property (nonatomic,retain) UIButton *crateQt;

@end
