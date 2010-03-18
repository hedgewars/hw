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
}

@property (nonatomic,retain) NSTimer *dimTimer;

-(IBAction) buttonReleased:(id) sender;
-(IBAction) buttonPressed:(id) sender;

-(void) dimOverlay;

@end
