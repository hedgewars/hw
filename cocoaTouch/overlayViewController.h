//
//  overlayViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface overlayViewController : UIViewController {
    NSTimer *dimTimer;
    CGFloat initialDistanceForPinching;
    CGPoint gestureStartPoint;
}

@property (nonatomic,retain) NSTimer *dimTimer;


-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;

-(IBAction) buttonReleased:(id) sender;
-(IBAction) buttonPressed:(id) sender;

-(void) dimOverlay;
-(void) showMenuAfterwards;

@end
