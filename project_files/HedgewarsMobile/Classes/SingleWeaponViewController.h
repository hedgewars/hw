//
//  SingleWeaponViewController.h
//  Hedgewars
//
//  Created by Vittorio on 19/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WeaponCellView.h"

@interface SingleWeaponViewController : UITableViewController <WeaponButtonControllerDelegate> {
    UIImage *ammoStoreImage;
    NSArray *ammoNames;
    
    char *quantity;
    char *probability;
    char *delay;
    char *crateness;
}

@property (nonatomic,retain) UIImage *ammoStoreImage;
@property (nonatomic,retain) NSArray *ammoNames;


@end
