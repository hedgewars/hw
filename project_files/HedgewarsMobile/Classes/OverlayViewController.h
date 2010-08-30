//
//  overlayViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDL_sysvideo.h"

@class InGameMenuViewController;
@class HelpPageLobbyViewController;

@interface OverlayViewController : UIViewController {
    // the timer that dims the overlay
    NSTimer *dimTimer;

    // the in-game menu
    UIPopoverController *popoverController; // iPad only
    InGameMenuViewController *popupMenu;
    BOOL isPopoverVisible;

    // the help menu
    HelpPageLobbyViewController *helpPage;

    // ths touch section
    CGFloat initialDistanceForPinching;
    CGPoint startingPoint;
    BOOL isSegmentVisible;
    BOOL isAttacking;

    // the sdl window underneath
    SDL_Window *sdlwindow;
}

@property (nonatomic,retain) id popoverController;
@property (nonatomic,retain) InGameMenuViewController *popupMenu;
@property (nonatomic,retain) HelpPageLobbyViewController *helpPage;

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

@end

// understands when the loading screen is done
BOOL isGameRunning;
// cache the grenade time
NSInteger cachedGrenadeTime;