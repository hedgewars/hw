//
//  WeaponCellView.h
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditableCellViewDelegate <NSObject>

-(void) saveTextFieldValue:(NSString *)textString;

@end

@interface EditableCellView : UITableViewCell <UITextFieldDelegate> {
    id<EditableCellViewDelegate> delegate;
    UITextField *textField;
}

@property (nonatomic,assign) id<EditableCellViewDelegate> delegate;
@property (nonatomic,retain,readonly) UITextField *textField;

-(void) replyKeyboard;
-(void) cancel:(id) sender;
-(void) save:(id) sender;

@end
