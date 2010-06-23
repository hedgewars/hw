//
//  overlayViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PopoverMenuViewController;

@interface OverlayViewController : UIViewController {
    NSTimer *dimTimer;

    // used only on the ipad
    UIPopoverController *popoverController;

    PopoverMenuViewController *popupMenu;
    BOOL isPopoverVisible;
    
    UITextField *writeChatTextField;
    
    CGFloat initialDistanceForPinching;
    CGPoint gestureStartPoint;
    UIActivityIndicatorView *spinningWheel;
}

@property (nonatomic,retain) id popoverController;
@property (nonatomic,retain) PopoverMenuViewController *popupMenu;
@property (nonatomic,retain) UITextField *writeChatTextField;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *spinningWheel;

UIActivityIndicatorView *singleton;
BOOL canDim;

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

-(IBAction) buttonReleased:(id) sender;
-(IBAction) buttonPressed:(id) sender;

-(void) showPopover;
-(void) dismissPopover;
-(void) dimOverlay;
-(void) activateOverlay;
-(void) chatAppear;
-(void) chatDisappear;

@end
