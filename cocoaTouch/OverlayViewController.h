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
#ifdef __IPHONE_3_2
    UIPopoverController *popoverController;
#else
    id popoverController;
#endif
    PopoverMenuViewController *popupMenu;
    BOOL isPopoverVisible;
    
    CGFloat initialDistanceForPinching;
    CGPoint gestureStartPoint;
}

@property (nonatomic,retain) NSTimer *dimTimer;
@property (nonatomic,retain) id popoverController;
@property (nonatomic,retain) PopoverMenuViewController *popupMenu;

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

-(IBAction) buttonReleased:(id) sender;
-(IBAction) buttonPressed:(id) sender;

-(void) showPopover;
-(void) dismissPopover;
-(void) dimOverlay;
-(void) showMenuAfterwards;

@end
