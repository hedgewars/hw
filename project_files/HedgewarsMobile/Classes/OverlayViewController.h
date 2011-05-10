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
 * File created on 16/03/2010.
 */


#import <UIKit/UIKit.h>

@class InGameMenuViewController;
@class HelpPageViewController;
@class AmmoMenuViewController;

@interface OverlayViewController : UIViewController {
    // the timer that dims the overlay
    NSTimer *dimTimer;

    // the in-game menu
    UIPopoverController *popoverController; // iPad only, never set on iPhone
    InGameMenuViewController *popupMenu;
    BOOL isPopoverVisible;

    // the help menu
    HelpPageViewController *helpPage;

    // the objc ammomenu
    AmmoMenuViewController *amvc;
    
    // ths touch section
    CGFloat initialDistanceForPinching;
    CGPoint startingPoint;
    BOOL isAttacking;
    
    // stuff initialized externally
    NSInteger initialOrientation;
    
    // dual head support
    NSInteger initialScreenCount;

    // various other widgets
    UIActivityIndicatorView *lowerIndicator;
    UIActivityIndicatorView *savesIndicator;
    UIButton *confirmButton;
    UISegmentedControl *grenadeTimeSegment;
}

@property (nonatomic,retain) id popoverController;
@property (nonatomic,retain) InGameMenuViewController *popupMenu;
@property (nonatomic,retain) HelpPageViewController *helpPage;
@property (nonatomic,retain) AmmoMenuViewController *amvc;
@property (nonatomic,retain) UIActivityIndicatorView *lowerIndicator;
@property (nonatomic,retain) UIActivityIndicatorView *savesIndicator;
@property (nonatomic,retain) UIButton *confirmButton;
@property (nonatomic,retain) UISegmentedControl *grenadeTimeSegment;

@property (assign) NSInteger initialOrientation;
@property (assign) NSInteger initialScreenCount;


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
-(void) removeOverlay;

#define ANIMATION_DURATION 0.25
#define CONFIRMATION_TAG 5959
#define GRENADE_TAG 9595

@end
