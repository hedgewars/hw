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
#import "PopoverMenuViewController.h"
#import "CommodityFunctions.h"

@implementation OverlayViewController
@synthesize popoverController, popupMenu;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


-(void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

-(void) didRotate:(NSNotification *)notification {	
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    CGRect rect = [[UIScreen mainScreen] bounds];
    
	if (orientation == UIDeviceOrientationLandscapeLeft) {
        [UIView beginAnimations:@"flip1" context:NULL];
        [UIView setAnimationDuration:0.8f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [[SDLUIKitDelegate sharedAppDelegate].uiwindow viewWithTag:SDL_VIEW_TAG].transform = CGAffineTransformMakeRotation(degreesToRadian(0));
        self.view.transform = CGAffineTransformMakeRotation(degreesToRadian(90));
        self.view.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
        [UIView commitAnimations];
	} else
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [UIView beginAnimations:@"flip2" context:NULL];
            [UIView setAnimationDuration:0.8f];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [[SDLUIKitDelegate sharedAppDelegate].uiwindow viewWithTag:SDL_VIEW_TAG].transform = CGAffineTransformMakeRotation(degreesToRadian(180));
            self.view.transform = CGAffineTransformMakeRotation(degreesToRadian(-90));
            self.view.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
            [UIView commitAnimations];
        }
}


-(void) viewDidLoad {

    isPopoverVisible = NO;
    self.view.alpha = 0;
    self.view.center = CGPointMake(self.view.frame.size.height/2.0, self.view.frame.size.width/2.0);
    
    
    dimTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:6]
                                        interval:1000
                                          target:self
                                        selector:@selector(dimOverlay)
                                        userInfo:nil
                                         repeats:YES];
    
    // add timer too runloop, otherwise it doesn't work
    [[NSRunLoop currentRunLoop] addTimer:dimTimer forMode:NSDefaultRunLoopMode];
    
    // listen for dismissal of the popover (see below)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissPopover)
                                                 name:@"dismissPopover"
                                               object:nil];
    // present the overlay after 2 seconds
    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(showMenuAfterwards)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) viewDidUnload {
    self.popoverController = nil;
    self.popupMenu = nil;
    [super viewDidUnload];
}

-(void) dealloc {
	[dimTimer invalidate];
    [popupMenu release];
    [popoverController release];
    // dimTimer is autoreleased
    [super dealloc];
}

// draws the controller overlay after the sdl window has taken control
-(void) showMenuAfterwards {
    [[SDLUIKitDelegate sharedAppDelegate].uiwindow bringSubviewToFront:self.view];
    
    // need to split paths because iphone doesn't rotate (so we don't need to subscribe to any notification
    // nor perform engine actions when rotating
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];	
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate:)
                                                     name:@"UIDeviceOrientationDidChangeNotification"
                                                   object:nil];
        
        [self didRotate:nil];
    } else 
        self.view.transform = CGAffineTransformRotate(self.view.transform, (M_PI/2.0));
    
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
    if (isPopoverVisible) {
        [self dismissPopover];
    }
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
            HW_tab();
            break;
        case 10:
            [self showPopover];
            break;
        default:
            NSLog(@"Nope");
            break;
    }
}

// present a further check before closing game
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
	if ([actionSheet cancelButtonIndex] != buttonIndex)
	    HW_terminate(NO);
	else
        HW_pause();		
}

// show up a popover containing a popupMenuViewController; we hook it with setPopoverContentSize
// on iphone instead just use the tableViewController directly (and implement manually all animations)
-(IBAction) showPopover{
    isPopoverVisible = YES;
    Class popoverControllerClass = NSClassFromString(@"UIPopoverController");
    if (popoverControllerClass) {
#ifdef __IPHONE_3_2
        popupMenu = [[PopoverMenuViewController alloc] initWithStyle:UITableViewStylePlain];
        popoverController = [[popoverControllerClass alloc] initWithContentViewController:popupMenu];
        [popoverController setPopoverContentSize:CGSizeMake(220, 170) animated:YES];
        [popoverController setPassthroughViews:[NSArray arrayWithObject:self.view]];
        
        [popoverController presentPopoverFromRect:CGRectMake(960, 0, 220, 32)
                                           inView:self.view
                         permittedArrowDirections:UIPopoverArrowDirectionUp 
                                         animated:YES];
#endif
    } else {
        popupMenu = [[PopoverMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];
        popupMenu.view.backgroundColor = [UIColor clearColor];
        popupMenu.view.frame = CGRectMake(480, 0, 200, 170);
        [self.view addSubview:popupMenu.view];

        [UIView beginAnimations:@"showing popover" context:NULL];
        [UIView setAnimationDuration:0.35];
        popupMenu.view.frame = CGRectMake(280, 0, 200, 170);
        [UIView commitAnimations];
    }
    popupMenu.tableView.scrollEnabled = NO;
}

// on ipad just dismiss it, on iphone transtion on the right
-(void) dismissPopover {
    if (YES == isPopoverVisible) {
        isPopoverVisible = NO;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
#ifdef __IPHONE_3_2
            [popoverController dismissPopoverAnimated:YES];
#endif
        } else {
            [UIView beginAnimations:@"hiding popover" context:NULL];
            [UIView setAnimationDuration:0.35];
            popupMenu.view.frame = CGRectMake(480, 0, 200, 170);
            [UIView commitAnimations];
        
            [popupMenu.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.35];
            [popupMenu performSelector:@selector(release) withObject:nil afterDelay:0.35];
            
            //[dimTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.7]];
        }
        [self buttonReleased:nil];
    }
}


#pragma mark -
#pragma mark Custom touch event handling

#define kMinimumPinchDelta      50


-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray *twoTouches;
	UITouch *touch = [touches anyObject];
    
    if (isPopoverVisible) {
        [self dismissPopover];
    }
    
    gestureStartPoint = [touch locationInView:self.view];
        
	switch ([touches count]) {
		case 1:
			initialDistanceForPinching = 0;
			switch ([touch tapCount]) {
				case 1:
					NSLog(@"X:%d Y:%d", (int)gestureStartPoint.x, (int)gestureStartPoint.y );
					//SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].window, 
					//		      (int)gestureStartPoint.y, width - (int)gestureStartPoint.x);
					//HW_click();
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
            gestureStartPoint.x = 0;
            gestureStartPoint.y = 0;
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
	HW_allKeysUp();
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// this can happen if the user puts more than 5 touches on the screen at once, or perhaps in other circumstances
	[self touchesEnded:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGFloat minimumGestureLength;
    int logCoeff;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        minimumGestureLength = 5.0f;
        logCoeff = 19;
    } else {
        minimumGestureLength = 3.0f;
        logCoeff = 3;
    }
    
	NSArray *twoTouches;
	CGPoint currentPosition;
	UITouch *touch = [touches anyObject];

	switch ([touches count]) {
		case 1:
			currentPosition = [touch locationInView:self.view];
			// panning
			CGFloat deltaX = fabsf(gestureStartPoint.x - currentPosition.x);
			CGFloat deltaY = fabsf(gestureStartPoint.y - currentPosition.y);
			
            if (deltaX >= minimumGestureLength) {
                NSLog(@"Horizontal swipe detected, deltaX: %f deltaY: %f",deltaX, deltaY);
                if (currentPosition.x > gestureStartPoint.x) {
                    HW_cursorLeft(logCoeff*log(deltaX));
                } else {
                    HW_cursorRight(logCoeff*log(deltaX));
                }

            } 
            if (deltaY >= minimumGestureLength) {
                NSLog(@"Horizontal swipe detected, deltaX: %f deltaY: %f",deltaX, deltaY);
                if (currentPosition.y < gestureStartPoint.y) {
                    HW_cursorDown(logCoeff*log(deltaY));
                } else {
                    HW_cursorUp(logCoeff*log(deltaY));
                }            
            }

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
