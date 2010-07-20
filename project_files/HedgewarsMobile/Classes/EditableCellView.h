//
//  WeaponCellView.h
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define MAX_STRING_LENGTH 64

@protocol EditableCellViewDelegate <NSObject>

-(void) saveTextFieldValue:(NSString *)textString withTag:(NSInteger) tagValue;

@end

@interface EditableCellView : UITableViewCell <UITextFieldDelegate> {
    id<EditableCellViewDelegate> delegate;
    UITextField *textField;
    
@private
    NSString *oldValue;
}

@property (nonatomic,assign) id<EditableCellViewDelegate> delegate;
@property (nonatomic,retain,readonly) UITextField *textField;
@property (nonatomic,retain) NSString *oldValue;

-(void) replyKeyboard;
-(void) cancel:(id) sender;
-(void) save:(id) sender;

@end
