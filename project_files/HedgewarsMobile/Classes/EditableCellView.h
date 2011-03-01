/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 03/07/2010.
 */


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
    BOOL respectEditing;

@private
    NSString *oldValue;
}

@property (nonatomic,assign) id<EditableCellViewDelegate> delegate;
@property (nonatomic,retain,readonly) UITextField *textField;
@property (nonatomic,retain,readonly) UILabel *titleLabel;
@property (nonatomic,assign) NSInteger minimumCharacters;
@property (nonatomic,assign) NSInteger maximumCharacters;
@property (nonatomic,assign) BOOL respectEditing;
@property (nonatomic,retain) NSString *oldValue;

-(void) replyKeyboard;
-(void) cancel:(id) sender;
-(void) save:(id) sender;

@end
