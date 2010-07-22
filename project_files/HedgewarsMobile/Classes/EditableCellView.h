//
//  WeaponCellView.h
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditableCellViewDelegate <NSObject>

-(void) saveTextFieldValue:(NSString *)textString withTag:(NSInteger) tagValue;

@end

@interface EditableCellView : UITableViewCell <UITextFieldDelegate> {
    id<EditableCellViewDelegate> delegate;
    UITextField *textField;
    UILabel *titleLabel;
    NSInteger minimumCharacters;
    NSInteger maximumCharacters;
    
@private
    NSString *oldValue;
}

@property (nonatomic,assign) id<EditableCellViewDelegate> delegate;
@property (nonatomic,retain,readonly) UITextField *textField;
@property (nonatomic,retain,readonly) UILabel *titleLabel;
@property (nonatomic,assign) NSInteger minimumCharacters;
@property (nonatomic,assign) NSInteger maximumCharacters;
@property (nonatomic,retain) NSString *oldValue;

-(void) replyKeyboard;
-(void) cancel:(id) sender;
-(void) save:(id) sender;

@end
