//
//  overlayViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "overlayViewController.h"
#import "PascalImports.h"

@implementation overlayViewController
@synthesize dimTimer;


-(void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

-(void) viewDidLoad {
    dimTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:6]
                                        interval:1000
                                          target:self
                                        selector:@selector(dimOverlay)
                                        userInfo:nil
                                         repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:dimTimer forMode:NSDefaultRunLoopMode];
}

-(void) viewDidUnload {
	[dimTimer invalidate];
}

-(void) dealloc {
    [dimTimer release];
    [super dealloc];
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

    UIButton *theButton = (UIButton*)sender;
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
        default:
            // HW_chat() HW_tab() HW_pause()
            break;
    }
}


@end
