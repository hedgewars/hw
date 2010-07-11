//
//  overlayViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CONFIRMATION_TAG 5959
#define removeConfirmationInput() [[self.view viewWithTag:CONFIRMATION_TAG] removeFromSuperview]

@class PopoverMenuViewController;

@interface OverlayViewController : UIViewController {
    NSTimer *dimTimer;

    // used only on the ipad
    UIPopoverController *popoverController;

    PopoverMenuViewController *popupMenu;
    BOOL isPopoverVisible;
    
    // touch section
    BOOL isSingleClick;
    CGFloat initialDistanceForPinching;
    CGPoint pointWhereToClick;
}

@property (nonatomic,retain) id popoverController;
@property (nonatomic,retain) PopoverMenuViewController *popupMenu;

BOOL isGameRunning;

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
