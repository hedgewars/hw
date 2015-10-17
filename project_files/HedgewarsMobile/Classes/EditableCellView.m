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


#import "EditableCellView.h"


@implementation EditableCellView
@synthesize delegate, textField, titleLabel, minimumCharacters, maximumCharacters, respectEditing, oldValue;

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        delegate = nil;

        textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.backgroundColor = [UIColor clearColor];
        textField.delegate = self;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.clearsOnBeginEditing = NO;
        textField.returnKeyType = UIReturnKeyDone;
        textField.adjustsFontSizeToFitWidth = YES;
        textField.minimumFontSize = 9;
        textField.userInteractionEnabled = YES;
        textField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        [textField addTarget:self action:@selector(save:) forControlEvents:UIControlEventEditingDidEndOnExit];

        [self.contentView addSubview:textField];
        //[textField release];

        titleLabel = [[UILabel alloc] init];
        titleLabel.textAlignment = UITextAlignmentLeft;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        [self.contentView addSubview:titleLabel];
        //[titleLabel release];

        minimumCharacters = 1;
        maximumCharacters = 64;
        respectEditing = NO;
        oldValue = nil;
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];

    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;

    int offset = 0;
    int skew = 0;
    if (self.imageView != nil)
        offset += self.imageView.frame.size.width;

    if ([self.titleLabel.text length] == 0)
        titleLabel.frame = CGRectZero;
    else {
        titleLabel.frame = CGRectMake(boundsX+offset+10, 10, 100, [UIFont labelFontSize] + 4);
        offset += 100;
        skew +=2;
    }

    textField.frame = CGRectMake(boundsX+offset+10, skew+10, 300, [UIFont labelFontSize] + 4);
}

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void) dealloc {
    self.delegate = nil;
    releaseAndNil(oldValue);
    releaseAndNil(titleLabel);
    releaseAndNil(textField);
    [super dealloc];
}

#pragma mark -
#pragma mark textField delegate
// limit the size of the field to 64 characters like in original frontend
-(BOOL) textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return !([aTextField.text length] > self.maximumCharacters && [string length] > range.length);
}

// allow editing only if delegate is set and conformant to protocol, and if editableOnlyWhileEditing
-(BOOL) textFieldShouldBeginEditing:(UITextField *)aTextField {
    return (delegate != nil) &&
           [delegate respondsToSelector:@selector(saveTextFieldValue:withTag:)] &&
           (respectEditing) ? ((UITableView*)[self superview]).editing : YES;
}

// the textfield is being modified, update the navigation controller
-(void) textFieldDidBeginEditing:(UITextField *)aTextField{
    // don't interact with table below
    ((UITableView*)[self superview]).scrollEnabled = NO;

    self.oldValue = self.textField.text;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",@"")
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancel:)];
    [(UITableViewController *)delegate navigationItem].leftBarButtonItem = cancelButton;
    [cancelButton release];

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",@"")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(save:)];
    [(UITableViewController *)delegate navigationItem].rightBarButtonItem = saveButton;
    [saveButton release];
}

/* with this a field might remain in editing status even if the view moved;
   use method below instead that allows some more interaction
// don't accept 0-length strings
-(BOOL) textFieldShouldEndEditing:(UITextField *)aTextField {
    return ([aTextField.text length] > 0);
}
*/

-(BOOL) textFieldShouldReturn:(UITextField *)aTextField {
    return ([aTextField.text length] >= self.minimumCharacters);
}

// the textfield has been modified, tell the delegate to do something
-(void) textFieldDidEndEditing:(UITextField *)aTextField {
    // this forces a save when user selects a new field
    if ([self.textField.text isEqualToString:self.oldValue] == NO)
        [self save:aTextField];

    // restores default behaviour on caller
    ((UITableView*)[self superview]).scrollEnabled = YES;
    [(UITableViewController *)delegate navigationItem].leftBarButtonItem = [(UITableViewController *)delegate navigationItem].backBarButtonItem;
    [(UITableViewController *)delegate navigationItem].rightBarButtonItem = nil;
}

#pragma mark -
#pragma mark instance methods
// the user wants to show the keyboard
-(void) replyKeyboard {
    [self.textField becomeFirstResponder];
}

// the user pressed cancel so hide keyboard
-(void) cancel:(id) sender {
    // reverts any changes and performs a fake save for removing the keyboard
    self.textField.text = self.oldValue;
    [self save:sender];
}

// send the value to the delegate (called before textFieldDidEndEditing)
-(void) save:(id) sender {
    if (delegate == nil || [delegate respondsToSelector:@selector(saveTextFieldValue:withTag:)] == NO)
        return;

    // don't save if the textfield is invalid
    if ([self textFieldShouldReturn:textField] == NO)
        return;

    [delegate saveTextFieldValue:self.textField.text withTag:self.tag];
    [self.textField resignFirstResponder];
    self.oldValue = nil;
}

// when field is editable only when the tableview is editable, resign responder when exiting editing mode
-(void) willTransitionToState:(UITableViewCellStateMask)state {
    if (respectEditing && state == UITableViewCellStateDefaultMask)
        [self save:nil];

    [super willTransitionToState:state];
}

@end
