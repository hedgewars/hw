//
//  SingleSchemeViewController.h
//  Hedgewars
//
//  Created by Vittorio on 23/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SingleSchemeViewController : UITableViewController <UITextFieldDelegate> {
    UITextField *textFieldBeingEdited;
    NSMutableArray *schemeArray;
    
    NSArray *basicSettingList;
    NSArray *gameModifierArray;
}

@property (nonatomic, retain) UITextField *textFieldBeingEdited;
@property (nonatomic, retain) NSMutableArray *schemeArray;
@property (nonatomic, retain) NSArray *basicSettingList;
@property (nonatomic, retain) NSArray *gameModifierArray;

@end
