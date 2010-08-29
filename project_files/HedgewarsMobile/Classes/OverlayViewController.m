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
#import "InGameMenuViewController.h"
#import "CommodityFunctions.h"
#import "SDL_config_iphoneos.h"

#define HIDING_TIME_DEFAULT [NSDate dateWithTimeIntervalSinceNow:2.7]
#define HIDING_TIME_NEVER   [NSDate dateWithTimeIntervalSinceNow:10000]
#define doDim()             [dimTimer setFireDate:HIDING_TIME_DEFAULT]
#define doNotDim()          [dimTimer setFireDate:HIDING_TIME_NEVER]

#define CONFIRMATION_TAG 5959
#define GRENADE_TAG 9595
#define ANIMATION_DURATION 0.25
#define removeConfirmationInput()   [[self.view viewWithTag:CONFIRMATION_TAG] removeFromSuperview];

@implementation OverlayViewController
@synthesize popoverController, popupMenu;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) didRotate:(NSNotification *)notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGRect usefulRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    UIView *sdlView = [[[UIApplication sharedApplication] keyWindow] viewWithTag:SDL_VIEW_TAG];

    [UIView beginAnimations:@"rotation" context:NULL];
    [UIView setAnimationDuration:0.8f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            sdlView.transform = CGAffineTransformMakeRotation(degreesToRadians(0));
            self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(90));
            HW_setLandscape(YES);
            break;
        case UIDeviceOrientationLandscapeRight:
            sdlView.transform = CGAffineTransformMakeRotation(degreesToRadians(180));
            self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(-90));
            HW_setLandscape(YES);
            break;
        /*
        case UIDeviceOrientationPortrait:
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                sdlView.transform = CGAffineTransformMakeRotation(degreesToRadian(270));
                self.view.transform = CGAffineTransformMakeRotation(degreesToRadian(0));
                [self chatAppear];
                HW_setLandscape(NO);
            }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                sdlView.transform = CGAffineTransformMakeRotation(degreesToRadian(90));
                self.view.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
                [self chatAppear];
                HW_setLandscape(NO);
            }
            break;
        */
        default:
            // a debug log would spam too much
            break;
    }
    self.view.frame = usefulRect;
    //sdlView.frame = usefulRect;
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark View Management
-(void) viewDidLoad {
    isAttacking = NO;
    
    // i called it a popover even on the iphone
    isPopoverVisible = NO;
    self.view.alpha = 0;
    self.view.center = CGPointMake(self.view.frame.size.height/2.0, self.view.frame.size.width/2.0);

    // set initial orientation wrt the controller orientation
    UIDeviceOrientation orientation = self.interfaceOrientation;
    UIView *sdlView = [[[UIApplication sharedApplication] keyWindow] viewWithTag:SDL_VIEW_TAG];
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            sdlView.transform = CGAffineTransformMakeRotation(degreesToRadians(0));
            self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(90));
            break;
        case UIDeviceOrientationLandscapeRight:
            sdlView.transform = CGAffineTransformMakeRotation(degreesToRadians(180));
            self.view.transform = CGAffineTransformMakeRotation(degreesToRadians(-90));
            break;
        default:
            DLog(@"unknown orientation");
            break;
    }
    CGRect rect = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);

    dimTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:6]
                                        interval:1000
                                          target:self
                                        selector:@selector(dimOverlay)
                                        userInfo:nil
                                         repeats:YES];

    // add timer too runloop, otherwise it doesn't work
    [[NSRunLoop currentRunLoop] addTimer:dimTimer forMode:NSDefaultRunLoopMode];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    [UIView beginAnimations:@"showing overlay" context:NULL];
    [UIView setAnimationDuration:1];
    self.view.alpha = 1;
    [UIView commitAnimations];

    // find the sdl window we're on
    SDL_VideoDevice *_this = SDL_GetVideoDevice();
    SDL_VideoDisplay *display = &_this->displays[0];
    sdlwindow = display->windows;
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if (self.popupMenu.view.superview == nil)
        self.popupMenu = nil;
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    // only objects initialized in viewDidLoad should be here
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dimTimer = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [popupMenu release];
    [popoverController release];
    // dimTimer is autoreleased
    [super dealloc];
}

#pragma mark -
#pragma mark Overlay actions and members
// nice transition for dimming, should be called only by the timer himself
-(void) dimOverlay {
    if (isGameRunning) {
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
    if (!isGameRunning)
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
    if (isPopoverVisible) {
        [self dismissPopover];
    }

    if (!isGameRunning)
        return;

    if (HW_isWaiting())
        HW_dismissReady();
    
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
            HW_pause();
            removeConfirmationInput();
            [self showPopover];
            break;
        case 11:
            removeConfirmationInput();
            HW_ammoMenu();
            break;
        default:
            DLog(@"Nope");
            break;
    }
}

-(void) unsetPreciseStatus {
    HW_preciseSet(NO);
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
    CGRect screen = [[UIScreen mainScreen] bounds];
    isPopoverVisible = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (popupMenu == nil)
            popupMenu = [[InGameMenuViewController alloc] initWithStyle:UITableViewStylePlain];
        if (popoverController == nil) {
            popoverController = [[UIPopoverController alloc] initWithContentViewController:popupMenu];
            [popoverController setPopoverContentSize:CGSizeMake(220, 170) animated:YES];
            [popoverController setPassthroughViews:[NSArray arrayWithObject:self.view]];
        }

        [popoverController presentPopoverFromRect:CGRectMake(screen.size.height / 2, screen.size.width / 2, 1, 1)
                                           inView:self.view
                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                         animated:YES];
    } else {
        if (popupMenu == nil)
            popupMenu = [[InGameMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];

        [self.view addSubview:popupMenu.view];
        [popupMenu present];
    }
    popupMenu.tableView.scrollEnabled = NO;
}

// on ipad just dismiss it, on iphone transtion to the right
-(void) dismissPopover {
    if (YES == isPopoverVisible) {
        isPopoverVisible = NO;
        if (HW_isPaused())
            HW_pause();

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [(InGameMenuViewController *)popoverController.contentViewController removeChat];
            [popoverController dismissPopoverAnimated:YES];
        } else {
            [popupMenu dismiss];
        }
        [self buttonReleased:nil];
    }
}

#pragma mark -
#pragma mark Custom touch event handling
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    UITouch *first, *second;

    if (isGameRunning == NO)
        return;

    // hide in-game menu
    if (isPopoverVisible)
        [self dismissPopover];

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

    //if (currentPosition.y < screen.size.width - 130 || (currentPosition.x > 130 && currentPosition.x < screen.size.height - 130)) {

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGRect screen = [[UIScreen mainScreen] bounds];
    NSSet *allTouches = [event allTouches];
    CGPoint currentPosition = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];

    switch ([allTouches count]) {
        case 1:
            // this dismisses the "get ready"
            if (HW_isWaiting())
                HW_dismissReady();

            // if we're in the menu we just click in the point
            if (HW_isAmmoOpen()) {
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
                            grenadeTime.selectedSegmentIndex = 2;
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

-(void) sendHWClick {
    HW_click();
    removeConfirmationInput();
    doDim();
}

-(void) setGrenadeTime:(id) sender {
    UISegmentedControl *theSegment = (UISegmentedControl *)sender;
    HW_setGrenadeTime(theSegment.selectedSegmentIndex + 1);
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGRect screen = [[UIScreen mainScreen] bounds];
    NSSet *allTouches = [event allTouches];
    int x, y, dx, dy;

    UITouch *touch, *first, *second;

    switch ([allTouches count]) {
        case 1:
            touch = [[allTouches allObjects] objectAtIndex:0];
            CGPoint currentPosition = [touch locationInView:self.view];

            if (HW_isAmmoOpen()) {
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
            break;
    }
}

#pragma mark -
#pragma mark Functions called by pascal
// called from AddProgress and FinishProgress (respectively)
void startSpinning() {
    isGameRunning = NO;
    CGRect screen = [[UIScreen mainScreen] bounds];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.tag = 987654;
    indicator.center = CGPointMake(screen.size.width/2 - 118, screen.size.height/2);
    indicator.hidesWhenStopped = YES;
    [indicator startAnimating];
    [[[[UIApplication sharedApplication] keyWindow] viewWithTag:SDL_VIEW_TAG] addSubview:indicator];
    [indicator release];
}

void stopSpinning() {
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[[[[UIApplication sharedApplication] keyWindow] viewWithTag:SDL_VIEW_TAG] viewWithTag:987654];
    [indicator stopAnimating];
    isGameRunning = YES;
    HW_zoomSet(1.7);
}

void clearView() {
    UIWindow *theWindow = [[UIApplication sharedApplication] keyWindow];
    UIButton *theButton = (UIButton *)[theWindow viewWithTag:CONFIRMATION_TAG];
    UISegmentedControl *theSegment = (UISegmentedControl *)[theWindow viewWithTag:GRENADE_TAG];

    [UIView beginAnimations:@"remove button" context:NULL];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    theButton.alpha = 0;
    theSegment.alpha = 0;
    [UIView commitAnimations];

    [theWindow performSelector:@selector(removeFromSuperview) withObject:theButton afterDelay:0.3];
    [theWindow performSelector:@selector(removeFromSuperview) withObject:theSegment afterDelay:0.3];
}

@end
