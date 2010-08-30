    //
//  HelpPageLobbyViewController.m
//  Hedgewars
//
//  Created by Vittorio on 30/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HelpPageViewController.h"
#import "CommodityFunctions.h"

@implementation HelpPageViewController


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) dealloc {
    [super dealloc];
}

-(IBAction) dismiss {
    [UIView beginAnimations:@"helpingame" context:NULL];
    self.view.alpha = 0;
    [UIView commitAnimations];
    [self.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
}

@end
