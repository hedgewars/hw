/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
#import "HelpPageInGameViewController.h"
#import "CGPointUtils.h"


#define HIDING_TIME_DEFAULT [NSDate dateWithTimeIntervalSinceNow:2.7]
#define HIDING_TIME_NEVER   [NSDate dateWithTimeIntervalSinceNow:10000]
#define doDim()             [dimTimer setFireDate:HIDING_TIME_DEFAULT]
#define doNotDim()          [dimTimer setFireDate:HIDING_TIME_NEVER]


@implementation OverlayViewController
@synthesize popoverController, popupMenu, helpPage, loadingIndicator, confirmButton, grenadeTimeSegment;

#pragma mark -
#pragma mark rotation

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark View Management
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        isAttacking = NO;
        isPopoverVisible = NO;
        loadingIndicator = nil;
    }
    return self;
}

-(void) viewDidLoad {
    // fill all the screen available as sdlview disables autoresizing
    self.view.frame = [[UIScreen mainScreen] safeBounds];
    // the timer used to dim the overlay
    dimTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:6]
                                        interval:1000
                                          target:self
                                        selector:@selector(dimOverlay)
                                        userInfo:nil
                                         repeats:YES];
    // add timer to runloop, otherwise it doesn't work
    [[NSRunLoop currentRunLoop] addTimer:dimTimer forMode:NSDefaultRunLoopMode];

    // display the help page, required by the popover on ipad
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHelp:)
                                                 name:@"show help ingame"
                                               object:nil];
    
    // present the overlay
    self.view.alpha = 0;
    [UIView beginAnimations:@"showing overlay" context:NULL];
    [UIView setAnimationDuration:2];
    self.view.alpha = 1;
    [UIView commitAnimations];
}

-(void) viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(unsetPreciseStatus)
                                               object:nil];

    // only objects initialized in viewDidLoad should be here
    dimTimer = nil;
    self.helpPage = nil;
    [self dismissPopover];
    self.popoverController = nil;
    self.loadingIndicator = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) didReceiveMemoryWarning {
    if (self.popupMenu.view.superview == nil)
        self.popupMenu = nil;
    if (self.helpPage.view.superview == nil)
        self.helpPage = nil;
    if (self.loadingIndicator.superview == nil)
        self.loadingIndicator = nil;
    if (self.confirmButton.superview == nil)
        self.confirmButton = nil;
    if (self.grenadeTimeSegment.superview == nil)
        self.grenadeTimeSegment = nil;
    if (IS_IPAD())
        if (((UIPopoverController *)self.popoverController).contentViewController.view.superview == nil)
            self.popoverController = nil;

    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) dealloc {
    releaseAndNil(popupMenu);
    releaseAndNil(helpPage);
    releaseAndNil(popoverController);
    releaseAndNil(loadingIndicator);
    releaseAndNil(confirmButton);
    releaseAndNil(grenadeTimeSegment);
    // dimTimer is autoreleased
    [super dealloc];
}

#pragma mark -
#pragma mark overlay appearance
// nice transition for dimming, should be called only by the timer himself
-(void) dimOverlay {
    if ([HWUtils isGameRunning]) {
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

-(void) clearOverlay {
    [UIView beginAnimations:@"remove button" context:NULL];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    self.confirmButton.alpha = 0;
    self.grenadeTimeSegment.alpha = 0;
    [UIView commitAnimations];

    if (self.confirmButton)
        [self.confirmButton performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:ANIMATION_DURATION];
    if (self.grenadeTimeSegment)
        [self.grenadeTimeSegment performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:ANIMATION_DURATION];
}

#pragma mark -
#pragma mark overlay user interaction
// dim the overlay when there's no more input for a certain amount of time
-(IBAction) buttonReleased:(id) sender {
    if ([HWUtils isGameRunning] == NO)
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
    
    if ([HWUtils isGameRunning] == NO)
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
            [AudioManagerController playClickSound];
            HW_pause();
            [self clearOverlay];
            [self showPopover];
            break;
        case 11:
            [AudioManagerController playClickSound];
            [self clearOverlay];
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

-(void) sendHWClick {
    [self clearOverlay];
    HW_click();
    doDim();
}

-(void) setGrenadeTime:(id) sender {
    UISegmentedControl *theSegment = (UISegmentedControl *)sender;
    NSInteger timeIndex = theSegment.selectedSegmentIndex + 1;
    if (HW_getGrenadeTime() != timeIndex)
        HW_setGrenadeTime(timeIndex);
}

#pragma mark -
#pragma mark in-game menu and help page
-(void) showHelp:(id) sender {
    if (self.helpPage == nil) {
        NSString *xibName = (IS_IPAD() ? @"HelpPageInGameViewController-iPad" : @"HelpPageInGameViewController-iPhone");
        self.helpPage = [[HelpPageInGameViewController alloc] initWithNibName:xibName bundle:nil];
    }
    self.helpPage.view.alpha = 0;
    [self.view addSubview:helpPage.view];
    [UIView beginAnimations:@"helpingame" context:NULL];
    self.helpPage.view.alpha = 1;
    [UIView commitAnimations];
    doNotDim();
}

// show up a popover containing a popupMenuViewController; we hook it with setPopoverContentSize
// on iphone instead just use the tableViewController directly (and implement manually all animations)
-(IBAction) showPopover{
    CGRect screen = [[UIScreen mainScreen] safeBounds];
    isPopoverVisible = YES;

    if (IS_IPAD()) {
        if (self.popupMenu == nil)
            self.popupMenu = [[InGameMenuViewController alloc] initWithStyle:UITableViewStylePlain];
        if (self.popoverController == nil) {
            self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.popupMenu];
            [self.popoverController setPopoverContentSize:CGSizeMake(220, 200) animated:YES];
            [self.popoverController setPassthroughViews:[NSArray arrayWithObject:self.view]];
        }

        [self.popoverController presentPopoverFromRect:CGRectMake(screen.size.width / 2, screen.size.height / 2, 1, 1)
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
            HW_pauseToggle();

        [self.popupMenu dismiss];
        if (IS_IPAD())
            [self.popoverController dismissPopoverAnimated:YES];

        [self buttonReleased:nil];
    }
}

#pragma mark -
#pragma mark Custom touch event handling
-(BOOL) shouldIgnoreTouch:(NSSet *)allTouches {
    if ([HWUtils isGameRunning] == NO)
        return YES;

    // ignore activity near the dpad and buttons
    CGPoint touchPoint = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];
    CGSize screen = [[UIScreen mainScreen] safeBounds].size;

    if ((touchPoint.x < 160 && touchPoint.y > screen.height - 155 ) ||
        (touchPoint.x > screen.width - 135 && touchPoint.y > screen.height - 140))
        return YES;
    return NO;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    UITouch *first, *second;

    if ([self shouldIgnoreTouch:allTouches] == YES)
        return;

    // hide in-game menu
    if (isPopoverVisible)
        [self dismissPopover];

    // reset default dimming
    doDim();

    HW_setPianoSound([allTouches count]);

    switch ([allTouches count]) {
        case 1:
            startingPoint = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];
            if (2 == [[[allTouches allObjects] objectAtIndex:0] tapCount])
                HW_zoomReset();
            break;
        case 2:
            if (2 == [[[allTouches allObjects] objectAtIndex:0] tapCount])
                HW_screenshot();
            else {
                // pinching
                first = [[allTouches allObjects] objectAtIndex:0];
                second = [[allTouches allObjects] objectAtIndex:1];
                initialDistanceForPinching = distanceBetweenPoints([first locationInView:self.view], [second locationInView:self.view]);
            }
            break;
        default:
            break;
    }
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    if ([self shouldIgnoreTouch:allTouches] == YES)
        return;

    CGRect screen = [[UIScreen mainScreen] safeBounds];
    CGPoint currentPosition = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];

    switch ([allTouches count]) {
        case 1:
            // if we're in the menu we just click in the point
            if (HW_isAmmoMenuOpen()) {
                HW_setCursor(HWXZ(currentPosition.x),HWYZ(currentPosition.y));
                // this click doesn't need any wrapping because the ammoMenu already limits the cursor
                HW_click();
            } else
                // if weapon requires a further click, ask for tapping again
                if (HW_isWeaponRequiringClick()) {
                    // here don't have to wrap thanks to isCursorVisible magic
                    HW_setCursor(HWX(currentPosition.x), HWY(currentPosition.y));

                    // draw the button at the last touched point (which is the current position)
                    if (self.confirmButton == nil) {
                        UIButton *tapAgain = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                        [tapAgain addTarget:self action:@selector(sendHWClick) forControlEvents:UIControlEventTouchUpInside];
                        [tapAgain setTitle:NSLocalizedString(@"Set!",@"on the overlay") forState:UIControlStateNormal];
                        self.confirmButton = tapAgain;
                    }
                    self.confirmButton.alpha = 0;
                    self.confirmButton.frame = CGRectMake(currentPosition.x - 75, currentPosition.y + 25, 150, 40);
                    [self.view addSubview:self.confirmButton];

                    // animation ftw!
                    [UIView beginAnimations:@"inserting button" context:NULL];
                    [UIView setAnimationDuration:ANIMATION_DURATION];
                    self.confirmButton.alpha = 1;
                    [UIView commitAnimations];

                    // keep the overlay active, or the button will fade
                    [self activateOverlay];
                    doNotDim();
                } else
                    if (HW_isWeaponTimerable()) {
                        if (self.grenadeTimeSegment.superview != nil) {
                            [UIView beginAnimations:@"removing segmented control" context:NULL];
                            [UIView setAnimationDuration:ANIMATION_DURATION];
                            self.grenadeTimeSegment.alpha = 0;
                            [UIView commitAnimations];

                            [self.grenadeTimeSegment performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:ANIMATION_DURATION];
                        } else {
                            if (self.grenadeTimeSegment == nil) {
                                NSArray *items = [[NSArray alloc] initWithObjects:@"1",@"2",@"3",@"4",@"5",nil];
                                UISegmentedControl *grenadeSegment = [[UISegmentedControl alloc] initWithItems:items];
                                [items release];
                                [grenadeSegment addTarget:self action:@selector(setGrenadeTime:) forControlEvents:UIControlEventValueChanged];
                                self.grenadeTimeSegment = grenadeSegment;
                                [grenadeSegment release];
                            }
                            self.grenadeTimeSegment.frame = CGRectMake(screen.size.width / 2 - 125, screen.size.height, 250, 50);
                            self.grenadeTimeSegment.selectedSegmentIndex = HW_getGrenadeTime() - 1;
                            self.grenadeTimeSegment.alpha = 1;
                            self.grenadeTimeSegment.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                                                       UIViewAutoresizingFlexibleRightMargin |
                                                                       UIViewAutoresizingFlexibleTopMargin;
                            [self.view addSubview:self.grenadeTimeSegment];

                            [UIView beginAnimations:@"inserting segmented control" context:NULL];
                            [UIView setAnimationDuration:ANIMATION_DURATION];
                            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                            self.grenadeTimeSegment.frame = CGRectMake(screen.size.width / 2 - 125, screen.size.height - 100, 250, 50);
                            [UIView commitAnimations];

                            [self activateOverlay];
                            doNotDim();
                        }
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
    NSSet *allTouches = [event allTouches];
    if ([self shouldIgnoreTouch:allTouches] == YES)
        return;

    CGRect screen = [[UIScreen mainScreen] safeBounds];
    int x, y, dx, dy;
    UITouch *touch, *first, *second;

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
            break;
    }
}

@end
