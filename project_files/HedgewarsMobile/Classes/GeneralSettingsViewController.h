//
//  SettingsViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditableCellView.h"

@interface GeneralSettingsViewController : UITableViewController <EditableCellViewDelegate> {
    NSMutableDictionary *settingsDictionary;
}

@property (nonatomic, retain) NSMutableDictionary *settingsDictionary;

@end
