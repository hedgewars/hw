//
//  overlayViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OverlayViewController.h"
#import "SDL_uikitappdelegate.h"
#import "PascalImports.h"
#import "CGPointUtils.h"
#import "SDL_mouse.h"
#import "PopupMenuViewController.h"

@implementation OverlayViewController
@synthesize dimTimer;


-(void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

-(void) viewDidLoad {
    self.view.alpha = 0;
    
    // needed for rotation to work on os < 3.2
    self.view.center = CGPointMake(self.view.frame.size.height/2.0, self.view.frame.size.width/2.0);
    self.view.transform = CGAffineTransformRotate(self.view.transform, (M_PI/2.0));

    dimTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:6]
                                        interval:1000
                                          target:self
                                        selector:@selector(dimOverlay)
                                        userInfo:nil
                                         repeats:YES];
    
    // add timer too runloop, otherwise it doesn't work
    [[NSRunLoop currentRunLoop] addTimer:dimTimer forMode:NSDefaultRunLoopMode];
    // listen for dismissal of the popover (see below)x
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPopover) name:@"dismissPopover" object:nil];
    // present the overlay after 2 seconds
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(showMenuAfterwards) userInfo:nil repeats:NO];
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

-(void) viewDidUnload {
	[dimTimer invalidate];
}

-(void) dealloc {
    // dimTimer is autoreleased
    [super dealloc];
}

// draws the controller overlay after the sdl window has taken control
-(void) showMenuAfterwards {
    [[SDLUIKitDelegate sharedAppDelegate].uiwindow bringSubviewToFront:self.view];

	[UIView beginAnimations:@"showing overlay" context:NULL];
	[UIView setAnimationDuration:1];
	self.view.alpha = 1;
	[UIView commitAnimations];
}

// dim the overlay when there's no more input for a certain amount of time
-(IBAction) buttonReleased:(id) sender {
	HW_allKeysUp();
    [dimTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.7]];
}

// nice transition for dimming
-(void) dimOverlay {
    [UIView beginAnimations:@"overlay dim" context:NULL];
   	[UIView setAnimationDuration:0.6];
    self.view.alpha = 0.2;
	[UIView commitAnimations];
}

// set the overlay visible and put off the timer for enough time
-(void) activateOverlay {
    self.view.alpha = 1;
    [dimTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1000]];
}

// issue certain action based on the tag of the button 
-(IBAction) buttonPressed:(id) sender {
    [self activateOverlay];
    UIActionSheet *actionSheet;
    UIButton *theButton = (UIButton *)sender;
    
    switch (theButton.tag) {
        case 0:
            HW_walkLeft();
            break;
        case 1:
            HW_walkRight();
            break;
        case 2:
            HW_aimUp();
            break;
        case 3:
            HW_aimDown();
            break;
        case 4:
            HW_shoot();
            break;
        case 5:
            HW_jump();
            break;
        case 6:
            HW_backjump();
            break;
        case 7:
            HW_pause();
            break;
        case 8:
            HW_chat();
            break;
        case 9:
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you reeeeeally sure?", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Well, maybe not...", @"")
                                        destructiveButtonTitle:NSLocalizedString(@"As sure as I can be!", @"")
                                             otherButtonTitles:nil];
            [actionSheet showInView:self.view];
            [actionSheet release];

            HW_pause();
	    break;
        case 10:
            HW_tab();
            break;
        default:
            NSLog(@"Nope");
            break;
    }
}

#pragma mark -
#define kMinimumPinchDelta      50
#define kMinimumGestureLength	10
#define kMaximumVariance        3

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray *twoTouches;
	UITouch *touch = [touches anyObject];
	
	switch ([touches count]) {
		case 1:
			gestureStartPoint = [touch locationInView:self.view];
			initialDistanceForPinching = 0;
			switch ([touch tapCount]) {
				case 1:
					NSLog(@"X:%d Y:%d", (int)gestureStartPoint.x, (int)gestureStartPoint.y );
					SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].window, 
							      (int)gestureStartPoint.y, 320 - (int)gestureStartPoint.x);
					HW_click();
					break;
				case 2:
					HW_ammoMenu();
					break;
				default:
					break;
			}
			break;
		case 2:
			if (2 == [touch tapCount]) {
				HW_zoomReset();
			}
			
			// pinching
			twoTouches = [touches allObjects];
			UITouch *first = [twoTouches objectAtIndex:0];
			UITouch *second = [twoTouches objectAtIndex:1];
			initialDistanceForPinching = distanceBetweenPoints([first locationInView:self.view], [second locationInView:self.view]);
			break;
		default:
			break;
	}

}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	initialDistanceForPinching = 0;
	gestureStartPoint.x = 0;
	gestureStartPoint.y = 0;
	HW_allKeysUp();
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// this can happen if the user puts more than 5 touches on the screen at once, or perhaps in other circumstances.
	[self touchesEnded:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray *twoTouches;
	CGPoint currentPosition;
	UITouch *touch = [touches anyObject];

	switch ([touches count]) {
		case 1:
			currentPosition = [touch locationInView:self.view];
			// panning
			SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].window, 
							(int)gestureStartPoint.y, 320 - (int)gestureStartPoint.x);
			// remember that we have x and y inverted
			/* temporarily disabling hog movements for camera panning testing
			CGFloat vertDiff = gestureStartPoint.x - currentPosition.x;
			CGFloat horizDiff = gestureStartPoint.y - currentPosition.y;
			CGFloat deltaX = fabsf(vertDiff);
			CGFloat deltaY = fabsf(horizDiff);
			
			if (deltaY >= kMinimumGestureLength && deltaX <= kMaximumVariance) {
				NSLog(@"Horizontal swipe detected, begX:%f curX:%f", gestureStartPoint.x, currentPosition.x);
				if (horizDiff > 0) HW_walkLeft();
				else HW_walkRight();
			} else if (deltaX >= kMinimumGestureLength && deltaY <= kMaximumVariance){
				NSLog(@"Vertical swipe detected, begY:%f curY:%f", gestureStartPoint.y, currentPosition.y);
				if (vertDiff < 0) HW_aimUp();
				else HW_aimDown();
			}
			*/
			break;
		case 2:
			twoTouches = [touches allObjects];
			UITouch *first = [twoTouches objectAtIndex:0];
			UITouch *second = [twoTouches objectAtIndex:1];
			CGFloat currentDistanceOfPinching = distanceBetweenPoints([first locationInView:self.view], [second locationInView:self.view]);
			
			if (0 == initialDistanceForPinching) 
				initialDistanceForPinching = currentDistanceOfPinching;

			if (currentDistanceOfPinching < initialDistanceForPinching + kMinimumPinchDelta)
				HW_zoomOut();
			else if (currentDistanceOfPinching > initialDistanceForPinching + kMinimumPinchDelta)
				HW_zoomIn();

			currentDistanceOfPinching = initialDistanceForPinching;
			break;
		default:
			break;
	}
}


@end
