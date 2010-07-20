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
@synthesize delegate, textField;

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
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];

    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    
    textField.frame = CGRectMake(boundsX+10, 11, 250, [UIFont labelFontSize] + 2);
}

/*
-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}
*/

-(void) dealloc {
    [textField release];
    [super dealloc];
}

#pragma mark -
#pragma mark textField delegate
// limit the size of the field to 64 characters like in original frontend
-(BOOL) textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    int limit = 64;
    return !([aTextField.text length] > limit && [string length] > range.length);
}

// allow editing only if delegate is set 
-(BOOL) textFieldShouldBeginEditing:(UITextField *)aTextField {
    return (delegate != nil);
}

// the textfield is being modified, update the navigation controller
-(void) textFieldDidBeginEditing:(UITextField *)aTextField{
    // don't scroll when editing
    ((UITableView*)[self superview]).scrollEnabled = NO;
    
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


// don't accept 0-length strings
-(BOOL) textFieldShouldEndEditing:(UITextField *)aTextField {
    return ([aTextField.text length] > 0); 
}

// the textfield has been modified, tell the delegate to do something
-(void) textFieldDidEndEditing:(UITextField *)aTextField{
    ((UITableView*)[self superview]).scrollEnabled = YES;
    
    [(UITableViewController *)delegate navigationItem].rightBarButtonItem = [(UITableViewController *)delegate navigationItem].backBarButtonItem;
    [(UITableViewController *)delegate navigationItem].leftBarButtonItem = nil;
}

-(void) replyKeyboard {
    [self.textField becomeFirstResponder];
}

// the user pressed cancel so hide keyboard
-(void) cancel:(id) sender {
    [self.textField resignFirstResponder];
}

// send the value to the delegate
-(void) save:(id) sender {
    if (delegate == nil)
        return;
    
    [delegate saveTextFieldValue:self.textField.text];
    [self.textField resignFirstResponder];
}

@end
