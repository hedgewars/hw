//
//  MapConfigViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 22/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MapConfigViewController.h"
#import "PascalImports.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"
#import "SDL_net.h"
#import <pthread.h>

#define INDICATOR_TAG 7654
#define RANDOMSTR_LEN 36
@implementation MapConfigViewController
@synthesize previewButton, maxHogs, seedCommand, templateFilterCommand, mapGenCommand, mazeSizeCommand,
            tableView, maxLabel, sizeLabel, segmentedControl, slider;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark Preview Handling
-(int) sendToEngine: (NSString *)string {
	unsigned char length = [string length];
	
	SDLNet_TCP_Send(csd, &length , 1);
	return SDLNet_TCP_Send(csd, [string UTF8String], length);
}

-(void) engineProtocol:(NSInteger) port {
	IPaddress ip;
	BOOL clientQuit, serverQuit;

    serverQuit = NO;
    clientQuit =NO;
	if (SDLNet_Init() < 0) {
		NSLog(@"SDLNet_Init: %s", SDLNet_GetError());
        serverQuit = YES;
	}
	
	/* Resolving the host using NULL make network interface to listen */
	if (SDLNet_ResolveHost(&ip, NULL, port) < 0) {
		NSLog(@"SDLNet_ResolveHost: %s\n", SDLNet_GetError());
        serverQuit = YES;
	}
	
	/* Open a connection with the IP provided (listen on the host's port) */
	if (!(sd = SDLNet_TCP_Open(&ip))) {
		NSLog(@"SDLNet_TCP_Open: %s %\n", SDLNet_GetError(), port);
        serverQuit = YES;
	}
	
	NSLog(@"engineProtocol - Waiting for a client on port %d", port);
	while (!serverQuit) {
		/* This check the sd if there is a pending connection.
		 * If there is one, accept that, and open a new socket for communicating */
		csd = SDLNet_TCP_Accept(sd);
		if (NULL != csd) {			
			NSLog(@"engineProtocol - Client found");
            
            [self sendToEngine:self.seedCommand];
            [self sendToEngine:self.templateFilterCommand];
            [self sendToEngine:self.mapGenCommand];
            [self sendToEngine:self.mazeSizeCommand];
            [self sendToEngine:@"!"];
                
            memset(map, 0, 128*32);
            SDLNet_TCP_Recv(csd, map, 128*32);
            SDLNet_TCP_Recv(csd, &maxHogs, sizeof(Uint8));

			SDLNet_TCP_Close(csd);
			serverQuit = YES;
		}
	}
	
	SDLNet_TCP_Close(sd);
	SDLNet_Quit();
}

-(void) drawingThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // select the port for IPC and launch the preview generation
    int port = randomPort();
    pthread_t thread_id;
    pthread_create(&thread_id, NULL, (void *)GenLandPreview, (void *)port);
    [self engineProtocol:port];

    // draw the buffer (1 pixel per component, 0= transparent 1= color)
    int xc = 0;
    int yc = 0;
    UIGraphicsBeginImageContext(CGSizeMake(256,128));      
    CGContextRef context = UIGraphicsGetCurrentContext();       
    UIGraphicsPushContext(context);  
    for (int i = 0; i < 32*128; i++) {
        unsigned char byte = map[i];
        for (int j = 0; j < 8; j++) {
            // select the color based on the rightmost bit
            if ((byte & 0x00000001) != 0)
                CGContextSetRGBFillColor(context, 0.5, 0.5, 0.7, 1.0);
            else
                CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.0);
            
            // draw pixel
            CGContextFillRect(context,CGRectMake(xc,yc,1,1));
            // move coordinates
            xc = (xc + 1) % 256;
            if (xc == 0) yc++;
            
            // shift to next bit
            byte = byte >> 1;
        }
    }
    UIGraphicsPopContext();
    UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    

    // set the preview image (autoreleased) in the button and the maxhog label
    [self.previewButton setBackgroundImage:previewImage forState:UIControlStateNormal];
    self.maxLabel.text = [NSString stringWithFormat:@"%d", maxHogs];
    
    // restore functionality of button and remove the spinning wheel
    [self turnOnWidgets];
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self.previewButton viewWithTag:INDICATOR_TAG];
    [indicator stopAnimating];
    [indicator removeFromSuperview];
    
    [pool release];
    [NSThread exit];

    /*
    // http://developer.apple.com/mac/library/qa/qa2001/qa1037.html
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapImage = CGBitmapContextCreate(mapExp, 128, 32, 8, 128, colorspace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorspace);
    
    CGImageRef previewCGImage = CGBitmapContextCreateImage(bitmapImage);
    UIImage *previewImage = [[UIImage alloc] initWithCGImage:previewCGImage];
    CGImageRelease(previewCGImage);
    */
}

-(void) turnOffWidgets {
    self.previewButton.alpha = 0.5f;
    self.previewButton.enabled = NO;
    self.maxLabel.text = @"...";
    self.segmentedControl.enabled = NO;
    self.tableView.allowsSelection = NO;
    self.slider.enabled = NO;
}

-(void) turnOnWidgets {
    self.previewButton.alpha = 1.0f;
    self.previewButton.enabled = YES;
    self.segmentedControl.enabled = YES;
    self.tableView.allowsSelection = YES;
    self.slider.enabled = YES;
}

-(IBAction) updatePreview {
    // prevent other events and add an activity while the preview is beign generated
    [self turnOffWidgets];
    
    // remove the current preview
    [self.previewButton setImage:nil forState:UIControlStateNormal];
    
    // add a very nice spinning wheel
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] 
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(previewButton.bounds.size.width / 2, previewButton.bounds.size.height / 2);
    indicator.tag = INDICATOR_TAG;
    [indicator startAnimating];
    [self.previewButton addSubview:indicator];
    [indicator release];

    // generate a seed
    char randomStr[RANDOMSTR_LEN+1];
    for (int i = 0; i < RANDOMSTR_LEN; ) {
        randomStr[i] = random() % 255;
        if (randomStr[i] >= '0' && randomStr[i] <= '9' || randomStr[i] >= 'a' && randomStr[i] <= 'z') 
            i++;
    }
    randomStr[ 8] = '-';
    randomStr[13] = '-';
    randomStr[18] = '-';
    randomStr[23] = '-';
    randomStr[RANDOMSTR_LEN] = '\0';
    NSString *seedCmd = [[NSString alloc] initWithFormat:@"eseed {%s}", randomStr];
    self.seedCommand = seedCmd;
    [seedCmd release];
    
    // let's draw in a separate thread so the gui can work; also it restores the preview button
    [NSThread detachNewThreadSelector:@selector(drawingThread) toTarget:self withObject:nil];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    
    return cell;
}

#pragma mark -
#pragma mark slider & segmentedControl
-(IBAction) sliderChanged:(id) sender {
    NSString *labelText;
    NSString *templateCommand;
    NSString *mazeCommand;
    
    switch ((int)(slider.value*100)) {
        case 0:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Wacky",@"");
            } else {
                labelText = NSLocalizedString(@"Large Floating Islands",@"");
            }
            templateCommand = @"e$template_filter 5";
            mazeCommand = @"e$maze_size 5";
            break;
        case 1:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Cavern",@"");
            } else {
                labelText = NSLocalizedString(@"Medium Floating Islands",@"");
            }
            templateCommand = @"e$template_filter 4";
            mazeCommand = @"e$maze_size 4";
            break;
        case 2:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Small",@"");
            } else {
                labelText = NSLocalizedString(@"Small Floating Islands",@"");
            }
            templateCommand = @"e$template_filter 1";
            mazeCommand = @"e$maze_size 3";
            break;
        case 3:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Medium",@"");
            } else {
                labelText = NSLocalizedString(@"Large Tunnels",@"");
            }
            templateCommand = @"e$template_filter 2";
            mazeCommand = @"e$maze_size 2";
            break;
        case 4:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"Large",@"");
            } else {
                labelText = NSLocalizedString(@"Medium Tunnels",@"");
            }
            templateCommand = @"e$template_filter 3";
            mazeCommand = @"e$maze_size 1";
            break;
        case 5:
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                labelText = NSLocalizedString(@"All",@"");
            } else {
                labelText = NSLocalizedString(@"Small Tunnels",@"");
            }
            templateCommand = @"e$template_filter 0";
            mazeCommand = @"e$maze_size 0";
            break;
        default:
            break;
    }
    self.sizeLabel.text = labelText;
    self.templateFilterCommand = templateCommand;
    self.mazeSizeCommand = mazeCommand;
}

// update preview as soon as the user lifts its finger
-(IBAction) sliderEndedChanging:(id) sender {
    if (self.previewButton.enabled == YES)
        [self updatePreview];
}

-(IBAction) segmentedControlChanged:(id) sender {
    NSString *mapgen;
    
    switch (segmentedControl.selectedSegmentIndex) {
        case 0: // Random
            mapgen = @"e$mapgen 0";
            [self sliderChanged:nil];
            if (self.previewButton.enabled == YES)
                [self updatePreview];
            break;
        case 1: // Map
            mapgen = @"e$mapgen 0";
            // other stuff
            break;
        case 2: // Maze
            mapgen = @"e$mapgen 1";
            [self sliderChanged:nil];
            if (self.previewButton.enabled == YES)
                [self updatePreview];

            break;
    }
    self.mapGenCommand = mapgen;
}

#pragma mark -
#pragma mark view management
-(void) viewDidLoad {
    srandom(time(NULL));
    [super viewDidLoad];

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.view.frame = CGRectMake(0, 0, screenSize.height, screenSize.width - 44);

    self.sizeLabel.text = NSLocalizedString(@"All",@"");
    self.templateFilterCommand = @"e$template_filter 0";
    self.segmentedControl.selectedSegmentIndex == 0;
    self.mazeSizeCommand = @"e$maze_size 0";
    self.mapGenCommand = @"e$mapgen 0";
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updatePreview];
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark memory
-(void) viewDidUnload {
    self.previewButton = nil;
    self.seedCommand = nil;
    self.seedCommand = nil;
    self.templateFilterCommand = nil;
    self.mapGenCommand = nil;
    self.mazeSizeCommand = nil;
    self.previewButton = nil;
    self.tableView = nil;
    self.maxLabel = nil;
    self.sizeLabel = nil;
    self.segmentedControl = nil;
    self.slider = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [seedCommand release];
    [templateFilterCommand release];
    [mapGenCommand release];
    [mazeSizeCommand release];
    [previewButton release];
    [tableView release];
    [maxLabel release];
    [sizeLabel release];
    [segmentedControl release];
    [slider release];
    [super dealloc];
}


@end
