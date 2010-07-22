//
//  WeaponCellView.m
//  Hedgewars
//
//  Created by Vittorio on 03/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EditableCellView.h"
#import "CommodityFunctions.h"

@implementation EditableCellView
@synthesize delegate, textField, titleLabel, minimumCharacters, maximumCharacters, oldValue;

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        delegate = nil;
        
        textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.backgroundColor = [UIColor clearColor];
        textField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        textField.delegate = self;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.clearsOnBeginEditing = NO;
        textField.returnKeyType = UIReturnKeyDone;
        textField.adjustsFontSizeToFitWidth = YES;
        [textField addTarget:self action:@selector(save:) forControlEvents:UIControlEventEditingDidEndOnExit];
        
        [self.contentView addSubview:textField];
        [textField release];
        
        titleLabel = [[UILabel alloc] init];
        titleLabel.textAlignment = UITextAlignmentLeft;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        [self.contentView addSubview:titleLabel];
        [titleLabel release];
        
        minimumCharacters = 1;
        maximumCharacters = 64;
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

    textField.frame = CGRectMake(boundsX+offset+10, skew+10, 250, [UIFont labelFontSize] + 4);
}

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void) dealloc {
    [oldValue release], oldValue = nil;
    [titleLabel release], titleLabel = nil;
    [textField release], textField = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark textField delegate
// limit the size of the field to 64 characters like in original frontend
-(BOOL) textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return !([aTextField.text length] > self.maximumCharacters && [string length] > range.length);
}

// allow editing only if delegate is set and conformant to protocol
-(BOOL) textFieldShouldBeginEditing:(UITextField *)aTextField {
    return (delegate != nil) && [delegate respondsToSelector:@selector(saveTextFieldValue:withTag:)];
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
-(void) textFieldDidEndEditing:(UITextField *)aTextField{
    ((UITableView*)[self superview]).scrollEnabled = YES;
    
    [(UITableViewController *)delegate navigationItem].rightBarButtonItem = [(UITableViewController *)delegate navigationItem].backBarButtonItem;
    [(UITableViewController *)delegate navigationItem].leftBarButtonItem = nil;
}

#pragma mark -
#pragma mark instance methods
// the user wants to show the keyboard
-(void) replyKeyboard {
    [self.textField becomeFirstResponder];
}

// the user pressed cancel so hide keyboard
-(void) cancel:(id) sender {
    self.textField.text = self.oldValue;
    [self save:sender];
}

// send the value to the delegate
-(void) save:(id) sender {
    if (delegate == nil || ![delegate respondsToSelector:@selector(saveTextFieldValue:withTag:)])
        return;
    
    // don't save if the textfield is invalid
    if (![self textFieldShouldReturn:textField])
        return;
    
    [delegate saveTextFieldValue:self.textField.text withTag:self.tag];
    [self.textField resignFirstResponder];
    self.oldValue = nil;
}

@end
