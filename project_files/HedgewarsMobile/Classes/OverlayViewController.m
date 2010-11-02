/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
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


#import "OverlayViewController.h"
#import "InGameMenuViewController.h"
#import "HelpPageViewController.h"
#import "AmmoMenuViewController.h"
#import "PascalImports.h"
#import "CommodityFunctions.h"
#import "CGPointUtils.h"
#import "SDL_config_iphoneos.h"
#import "SDL_mouse.h"
#import "ObjcExports.h"

#define HIDING_TIME_DEFAULT [NSDate dateWithTimeIntervalSinceNow:2.7]
#define HIDING_TIME_NEVER   [NSDate dateWithTimeIntervalSinceNow:10000]
#define doDim()             [dimTimer setFireDate: (IS_DUALHEAD()) ? HIDING_TIME_NEVER : HIDING_TIME_DEFAULT]
#define doNotDim()          [dimTimer setFireDate:HIDING_TIME_NEVER]

#define removeConfirmationInput()   [[self.view viewWithTag:CONFIRMATION_TAG] removeFromSuperview];

@implementation OverlayViewController
@synthesize popoverController, popupMenu, helpPage, amvc, isNetGame, useClassicMenu;

#pragma mark -
#pragma mark rotation
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

// pause the game and remove objc menus so that animation is smoother
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation duration:(NSTimeInterval) duration{
    [self dismissPopover];
    if (HW_isPaused() == NO)
        HW_pause();
    if (self.amvc.isVisible && IS_DUALHEAD() == NO) {
        [self.amvc disappear];
        wasVisible = YES;
    } else
        wasVisible = NO;

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    UIView *sdlView = [[[UIApplication sharedApplication] keyWindow] viewWithTag:SDL_VIEW_TAG];
    switch (toInterfaceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            sdlView.transform = CGAffineTransformMakeRotation(degreesToRadians(a));
            break;
        case UIDeviceOrientationLandscapeRight:
            sdlView.transform = CGAffineTransformMakeRotation(degreesToRadians(b));
            break;
        default:
            // a debug log would spam too much
            break;
    }
}

// now restore previous state
-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) fromInterfaceOrientation {
    if (wasVisible || IS_DUALHEAD())
        [self.amvc appearInView:self.view];
    if (HW_isPaused() == YES)
        HW_pause();

    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

// while in dual head the above rotation functions are not called
-(void) dualHeadRotation:(NSNotification *)notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    [UIView beginAnimations:@"rotation" context:NULL];
    [UIView setAnimationDuration:0.7];
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            self.view.frame = [[UIScreen mainScreen] bounds];
            self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(90));
            break;
        case UIDeviceOrientationLandscapeRight:
            self.view.frame = [[UIScreen mainScreen] bounds];
            self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(-90));
            break;
        default:
            // a debug log would spam too much
            break;
    }
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark View Management
-(id) initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        objcExportsInit();
        isAttacking = NO;
        wasVisible = NO;
        isPopoverVisible = NO;    // it is called "popover" even on the iphone
    }
    return self;
}

-(void) viewDidLoad {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width);
    self.view.center = CGPointMake(self.view.frame.size.height/2, self.view.frame.size.width/2);
    self.view.alpha = 0;

    // detrmine the quanitiy and direction of the rotation
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        a = 180;
        b = 0;
    } else {
        a = 0;
        b = 180;
    }

    // get the number of screens to know the previous state whan a display is connected or detached
    if ([UIScreen respondsToSelector:@selector(screens)])
        initialScreenCount = [[UIScreen screens] count];
    else
        initialScreenCount = 1;

    // set initial orientation of the controller orientation
    if (IS_DUALHEAD()) {
        switch (self.interfaceOrientation) {
            case UIDeviceOrientationLandscapeLeft:
                self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(90));
                break;
            case UIDeviceOrientationLandscapeRight:
                self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(-90));
                break;
            default:
                DLog(@"Nope");
                break;
        }
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dualHeadRotation:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }

    // the timer used to dim the overlay
    dimTimer = [[NSTimer alloc] initWithFireDate:(IS_DUALHEAD()) ? HIDING_TIME_NEVER : [NSDate dateWithTimeIntervalSinceNow:6]
                                        interval:1000
                                          target:self
                                        selector:@selector(dimOverlay)
                                        userInfo:nil
                                         repeats:YES];
    // add timer to runloop, otherwise it doesn't work
    [[NSRunLoop currentRunLoop] addTimer:dimTimer forMode:NSDefaultRunLoopMode];

    // become listener of some notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHelp:)
                                                 name:@"show help ingame"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanup)
                                                 name:@"remove overlay"
                                               object:nil];

    // for iOS >= 3.2
    if ([UIScreen respondsToSelector:@selector(screens)]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(numberOfScreensIncreased)
                                                     name:UIScreenDidConnectNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(numberOfScreensDecreased)
                                                     name:UIScreenDidDisconnectNotification
                                                   object:nil];
    }

    // present the overlay
    [UIView beginAnimations:@"showing overlay" context:NULL];
    [UIView setAnimationDuration:2];
    self.view.alpha = 1;
    [UIView commitAnimations];
}

-(void) numberOfScreensIncreased {
    if (initialScreenCount == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New display detected"
                                                        message:NSLocalizedString(@"Hedgewars supports multi-monitor configurations, but the screen has to be connected before launching the game.",@"")
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        if (HW_isPaused() == NO)
            HW_pause();
    }
}

-(void) numberOfScreensDecreased {
    if (initialScreenCount == 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh noes! Display disconnected"
                                                        message:NSLocalizedString(@"A monitor has been disconnected while playing and this has ended the match! You need to restart the game if you wish to use the second display again.",@"")
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        [self cleanup];
    }
}


-(void) showHelp:(id) sender {
    if (self.helpPage == nil)
        self.helpPage = [[HelpPageViewController alloc] initWithNibName:@"HelpPageInGameViewController" bundle:nil];
    self.helpPage.view.alpha = 0;
    [self.view addSubview:helpPage.view];
    [UIView beginAnimations:@"helpingame" context:NULL];
    self.helpPage.view.alpha = 1;
    [UIView commitAnimations];
    doNotDim();
}

-(void) cleanup {
    [self dismissPopover];
    setGameRunning(NO);
    HW_terminate(NO);
    [self.view removeFromSuperview];
}

-(void) didReceiveMemoryWarning {
    if (self.popupMenu.view.superview == nil)
        self.popupMenu = nil;
    if (self.helpPage.view.superview == nil)
        self.helpPage = nil;
    if (self.amvc.view.superview == nil)
        self.amvc = nil;
    if (IS_IPAD())
        if (((UIPopoverController *)self.popoverController).contentViewController.view.superview == nil)
            self.popoverController = nil;
    
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    // only objects initialized in viewDidLoad should be here
    if (IS_DUALHEAD())
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(unsetPreciseStatus)
                                               object:nil];
    dimTimer = nil;
    self.helpPage = nil;
    [self dismissPopover];
    self.popoverController = nil;
    self.amvc = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [popupMenu release];
    [helpPage release];
    [popoverController release];
    [amvc release];
    // dimTimer is autoreleased
    [super dealloc];
}

#pragma mark -
#pragma mark overlay user interaction
// nice transition for dimming, should be called only by the timer himself
-(void) dimOverlay {
    if (isGameRunning()) {
        [UIView beginAnimations:@"overlay dim" context:NULL];
        [UIView setAnimationDuration:0.6];
        self.view.alpha = 0.2;
        [UIView commitAnimations];
    }
}

// set the overlay visible and put off the timer for enough time
-(void) activateOverlay {
    self.view.alpha = 1;
    doNotDim();
}

// dim the overlay when there's no more input for a certain amount of time
-(IBAction) buttonReleased:(id) sender {
    if (isGameRunning() == NO)
        return;

    UIButton *theButton = (UIButton *)sender;

    switch (theButton.tag) {
        case 0:
        case 1:
        case 2:
        case 3:
            [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                     selector:@selector(unsetPreciseStatus)
                                                       object:nil];
            HW_walkingKeysUp();
            break;
        case 4:
        case 5:
        case 6:
            HW_otherKeysUp();
            break;
        default:
            DLog(@"Nope");
            break;
    }

    isAttacking = NO;
    doDim();
}

// issue certain action based on the tag of the button
-(IBAction) buttonPressed:(id) sender {
    [self activateOverlay];
    
    if (isGameRunning() == NO)
        return;
    
    if (isPopoverVisible)
        [self dismissPopover];
    
    UIButton *theButton = (UIButton *)sender;
    switch (theButton.tag) {
        case 0:
            if (isAttacking == NO)
                HW_walkLeft();
            break;
        case 1:
            if (isAttacking == NO)
                HW_walkRight();
            break;
        case 2:
            [self performSelector:@selector(unsetPreciseStatus) withObject:nil afterDelay:0.8];
            HW_preciseSet(!HW_isWeaponRope());
            HW_aimUp();
            break;
        case 3:
            [self performSelector:@selector(unsetPreciseStatus) withObject:nil afterDelay:0.8];
            HW_preciseSet(!HW_isWeaponRope());
            HW_aimDown();
            break;
        case 4:
            HW_shoot();
            isAttacking = YES;
            break;
        case 5:
            HW_jump();
            break;
        case 6:
            HW_backjump();
            break;
        case 10:
            playSound(@"clickSound");
            HW_pause();
            if (self.amvc.isVisible && IS_DUALHEAD() == NO) {
                doDim();
                [self.amvc disappear];
            }
            removeConfirmationInput();
            [self showPopover];
            break;
        case 11:
            playSound(@"clickSound");
            removeConfirmationInput();
            
            if (IS_DUALHEAD() || self.useClassicMenu == NO) {
                if (self.amvc == nil)
                    self.amvc = [[AmmoMenuViewController alloc] init];

                if (self.amvc.isVisible) {
                    doDim();
                    [self.amvc disappear];
                } else {
                    if (HW_isAmmoMenuNotAllowed() == NO) {
                        doNotDim();
                        [self.amvc appearInView:self.view];
                    }
                }
            } else {
                HW_ammoMenu();
            }
            break;
        default:
            DLog(@"Nope");
            break;
    }
}

-(void) unsetPreciseStatus {
    HW_preciseSet(NO);
}

-(void) sendHWClick {
    HW_click();
    removeConfirmationInput();
    doDim();
}

-(void) setGrenadeTime:(id) sender {
    UISegmentedControl *theSegment = (UISegmentedControl *)sender;
    if (cachedGrenadeTime() != theSegment.selectedSegmentIndex) {
        HW_setGrenadeTime(theSegment.selectedSegmentIndex + 1);
        setGrenadeTime(theSegment.selectedSegmentIndex);
    }
}

#pragma mark -
#pragma mark other menu
// present a further check before closing game
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
    if ([actionSheet cancelButtonIndex] != buttonIndex)
        [self cleanup];
    else
        HW_pause();
}

// show up a popover containing a popupMenuViewController; we hook it with setPopoverContentSize
// on iphone instead just use the tableViewController directly (and implement manually all animations)
-(IBAction) showPopover{
    CGRect screen = [[UIScreen mainScreen] bounds];
    isPopoverVisible = YES;

    if (IS_IPAD()) {
        if (self.popupMenu == nil)
            self.popupMenu = [[InGameMenuViewController alloc] initWithStyle:UITableViewStylePlain];
        if (self.popoverController == nil) {
            self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.popupMenu];
            [self.popoverController setPopoverContentSize:CGSizeMake(220, 170) animated:YES];
            [self.popoverController setPassthroughViews:[NSArray arrayWithObject:self.view]];
        }

        [self.popoverController presentPopoverFromRect:CGRectMake(screen.size.height / 2, screen.size.width / 2, 1, 1)
                                           inView:self.view
                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                         animated:YES];
    } else {
        if (self.popupMenu == nil)
            self.popupMenu = [[InGameMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];

        [self.view addSubview:popupMenu.view];
        [self.popupMenu present];
    }
    self.popupMenu.tableView.scrollEnabled = NO;
}

// on ipad just dismiss it, on iphone transtion to the right
-(void) dismissPopover {
    if (YES == isPopoverVisible) {
        isPopoverVisible = NO;
        if (HW_isPaused())
            HW_pause();

        if (IS_IPAD()) {
            [(InGameMenuViewController *)[[self popoverController] contentViewController] removeChat];
            [self.popoverController dismissPopoverAnimated:YES];
        } else {
            [self.popupMenu dismiss];
        }
        [self buttonReleased:nil];
    }
}

#pragma mark -
#pragma mark Custom touch event handling
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    UITouch *first, *second;

    if (isGameRunning() == NO)
        return;

    // hide in-game menu
    if (isPopoverVisible)
        [self dismissPopover];

    if (self.amvc.isVisible && IS_DUALHEAD() == NO) {
        doDim();
        [self.amvc disappear];
    }
    // reset default dimming
    doDim();

    HW_setPianoSound([allTouches count]);

    switch ([allTouches count]) {
        case 1:
            removeConfirmationInput();
            startingPoint = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];
            if (2 == [[[allTouches allObjects] objectAtIndex:0] tapCount])
                HW_zoomReset();
            break;
        case 2:
            // pinching
            first = [[allTouches allObjects] objectAtIndex:0];
            second = [[allTouches allObjects] objectAtIndex:1];
            initialDistanceForPinching = distanceBetweenPoints([first locationInView:self.view], [second locationInView:self.view]);
            break;
        default:
            break;
    }
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGRect screen = [[UIScreen mainScreen] bounds];
    NSSet *allTouches = [event allTouches];
    CGPoint currentPosition = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];

    if (isGameRunning() == NO)
        return;
    
    switch ([allTouches count]) {
        case 1:
            // if we're in the menu we just click in the point
            if (HW_isAmmoMenuOpen()) {
                HW_setCursor(HWXZ(currentPosition.x), HWYZ(currentPosition.y));
                // this click doesn't need any wrapping because the ammoMenu already limits the cursor
                HW_click();
            } else
                // if weapon requires a further click, ask for tapping again
                if (HW_isWeaponRequiringClick()) {
                    // here don't have to wrap thanks to isCursorVisible magic
                    HW_setCursor(HWX(currentPosition.x), HWY(currentPosition.y));

                    // draw the button at the last touched point (which is the current position)
                    UIButton *tapAgain = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                    tapAgain.frame = CGRectMake(currentPosition.x - 75, currentPosition.y + 25, 150, 40);
                    tapAgain.tag = CONFIRMATION_TAG;
                    tapAgain.alpha = 0;
                    [tapAgain addTarget:self action:@selector(sendHWClick) forControlEvents:UIControlEventTouchUpInside];
                    [tapAgain setTitle:NSLocalizedString(@"Tap to set!",@"from the overlay") forState:UIControlStateNormal];
                    [self.view addSubview:tapAgain];

                    // animation ftw!
                    [UIView beginAnimations:@"inserting button" context:NULL];
                    [UIView setAnimationDuration:ANIMATION_DURATION];
                    [self.view viewWithTag:CONFIRMATION_TAG].alpha = 1;
                    [UIView commitAnimations];

                    // keep the overlay active, or the button will fade
                    [self activateOverlay];
                    doNotDim();
                } else
                    if (HW_isWeaponTimerable()) {
                        if (isSegmentVisible) {
                            UISegmentedControl *grenadeTime = (UISegmentedControl *)[self.view viewWithTag:GRENADE_TAG];

                            [UIView beginAnimations:@"removing segmented control" context:NULL];
                            [UIView setAnimationDuration:ANIMATION_DURATION];
                            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                            grenadeTime.frame = CGRectMake(screen.size.height / 2 - 125, screen.size.width, 250, 50);
                            [UIView commitAnimations];

                            [grenadeTime performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:ANIMATION_DURATION];
                        } else {
                            NSArray *items = [[NSArray alloc] initWithObjects:@"1",@"2",@"3",@"4",@"5",nil];
                            UISegmentedControl *grenadeTime = [[UISegmentedControl alloc] initWithItems:items];
                            [items release];

                            [grenadeTime addTarget:self action:@selector(setGrenadeTime:) forControlEvents:UIControlEventValueChanged];
                            grenadeTime.frame = CGRectMake(screen.size.height / 2 - 125, screen.size.width, 250, 50);
                            grenadeTime.selectedSegmentIndex = cachedGrenadeTime();
                            grenadeTime.tag = GRENADE_TAG;
                            [self.view addSubview:grenadeTime];
                            [grenadeTime release];

                            [UIView beginAnimations:@"inserting segmented control" context:NULL];
                            [UIView setAnimationDuration:ANIMATION_DURATION];
                            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                            grenadeTime.frame = CGRectMake(screen.size.height / 2 - 125, screen.size.width - 100, 250, 50);
                            [UIView commitAnimations];

                            [self activateOverlay];
                            doNotDim();
                        }
                        isSegmentVisible = !isSegmentVisible;
                    } else
                        if (HW_isWeaponSwitch())
                            HW_tab();
            break;
        case 2:
            HW_allKeysUp();
            break;
        default:
            break;
    }

    initialDistanceForPinching = 0;
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGRect screen = [[UIScreen mainScreen] bounds];
    NSSet *allTouches = [event allTouches];
    int x, y, dx, dy;
    UITouch *touch, *first, *second;

    if (isGameRunning() == NO)
        return;
    
    switch ([allTouches count]) {
        case 1:
            touch = [[allTouches allObjects] objectAtIndex:0];
            CGPoint currentPosition = [touch locationInView:self.view];

            if (HW_isAmmoMenuOpen()) {
                // no zoom consideration for this
                HW_setCursor(HWXZ(currentPosition.x), HWYZ(currentPosition.y));
            } else
                if (HW_isWeaponRequiringClick()) {
                    // moves the cursor around wrt zoom
                    HW_setCursor(HWX(currentPosition.x), HWY(currentPosition.y));
                } else {
                    // panning \o/
                    dx = startingPoint.x - currentPosition.x;
                    dy = currentPosition.y - startingPoint.y;
                    HW_getCursor(&x, &y);
                    // momentum (or something like that)
                    /*if (abs(dx) > 40)
                        dx *= log(abs(dx)/4);
                    if (abs(dy) > 40)
                        dy *= log(abs(dy)/4);*/
                    HW_setCursor(x + dx/HW_zoomFactor(), y + dy/HW_zoomFactor());
                    startingPoint = currentPosition;
                }
            break;
        case 2:
            first = [[allTouches allObjects] objectAtIndex:0];
            second = [[allTouches allObjects] objectAtIndex:1];
            CGFloat currentDistanceOfPinching = distanceBetweenPoints([first locationInView:self.view], [second locationInView:self.view]);
            const int pinchDelta = 40;

            if (0 != initialDistanceForPinching) {
                if (currentDistanceOfPinching - initialDistanceForPinching > pinchDelta) {
                    HW_zoomIn();
                    initialDistanceForPinching = currentDistanceOfPinching;
                }
                else if (initialDistanceForPinching - currentDistanceOfPinching > pinchDelta) {
                    HW_zoomOut();
                    initialDistanceForPinching = currentDistanceOfPinching;
                }
            } else
                initialDistanceForPinching = currentDistanceOfPinching;
            break;
        default:
            DLog(@"Nope");
            break;
    }
}

@end
