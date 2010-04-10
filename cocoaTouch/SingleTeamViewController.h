//
//  SingleTeamViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HogHatViewController;
@interface SingleTeamViewController : UITableViewController <UITextFieldDelegate> {
    NSMutableDictionary *teamDictionary;
    
    UITextField *textFieldBeingEdited;
    NSInteger selectedHog;
    NSString *teamName;
    NSArray *hatArray;
    
    NSArray *secondaryItems;
    NSArray *secondaryControllers;
    BOOL isWriteNeeded;
    
    HogHatViewController *hogChildController;
}

@property (nonatomic,retain) NSMutableDictionary *teamDictionary;
@property (nonatomic,retain) UITextField *textFieldBeingEdited;
@property (nonatomic,retain) NSString *teamName;
@property (nonatomic,retain) NSArray *hatArray;
@property (nonatomic,retain) NSArray *secondaryItems;
@property (nonatomic,retain) NSArray *secondaryControllers;

-(void) writeFile;
-(void) setWriteNeeded;

@end
