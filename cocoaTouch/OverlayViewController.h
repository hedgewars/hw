//
//  overlayViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OverlayViewController : UIViewController {
    NSTimer *dimTimer;
    id menuPopover;     //UIPopoverController
    
    CGFloat initialDistanceForPinching;
    CGPoint gestureStartPoint;
    BOOL popoverVisible;
}

@property (nonatomic,retain) NSTimer *dimTimer;
@property (nonatomic,retain) id menuPopover;

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;

-(IBAction) buttonReleased:(id) sender;
-(IBAction) buttonPressed:(id) sender;
-(IBAction) showPopover;

-(void) dimOverlay;
-(void) showMenuAfterwards;

@end
