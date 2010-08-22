    //
//  AboutViewController.m
//  Hedgewars
//
//  Created by Vittorio on 01/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "CommodityFunctions.h"

@implementation AboutViewController


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) viewDidLoad {
    self.view.frame = CGRectMake(0, 0, 320, 480);
    [super viewDidLoad];
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

-(IBAction) buttonPressed:(id) sender {
    [[self parentViewController] dismissModalViewControllerAnimated:YES];
}

@end
