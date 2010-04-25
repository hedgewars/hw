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

@implementation MapConfigViewController
@synthesize previewButton, maxHogs, seedCommand;


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
            [self sendToEngine:@"e$template_filter 1"];
            [self sendToEngine:@"e$mapgen 0"];
            [self sendToEngine:@"e$maze_size 1"];
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


-(void) updatePreview {
    pthread_t thread_id;
    
    // generate a seed
    char randomStr[36];
    for (int i = 0; i<36; i++) {
         randomStr[i] = random()%255;
    }
    NSString *seedCmd = [[NSString alloc] initWithFormat:@"eseed {%s}", randomStr];
    self.seedCommand = seedCmd;
    [seedCmd release];
    
    // select the port for IPC
    int port = randomPort();
    pthread_create(&thread_id, NULL, (void *)GenLandPreview, (void *)port);
    [self engineProtocol:port];

    // draw the buffer (1 pixel per component, 0= transparent 1= color)
    int xc = 0;
    int yc = 0;
    UIGraphicsBeginImageContext(CGSizeMake(256,128));      
    CGContextRef context = UIGraphicsGetCurrentContext();       
    UIGraphicsPushContext(context);  
    for (int x = 0; x < 32*128; x++) {
        unsigned char byte = map[x];
        for (int z = 0; z < 8; z++) {
            // select the color
            if ((byte & 0x00000001) != 0)
                CGContextSetRGBFillColor(context, 0.5, 0.5, 0.7, 1.0);
            else
                CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.0);
            
            // draw pixel
            CGContextFillRect(context,CGRectMake(xc,yc,1,1));
            // move coordinates
            xc = (xc+1)%256;
            if (xc == 0) yc++;
            
            // shift to next bit
            byte = byte >> 1;
        }
    }
    UIGraphicsPopContext();
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    /*
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapImage = CGBitmapContextCreate(mapExp, 128, 32, 8, 128, colorspace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorspace);
    
    CGImageRef previewCGImage = CGBitmapContextCreateImage(bitmapImage);
    UIImage *previewImage = [[UIImage alloc] initWithCGImage:previewCGImage];
    CGImageRelease(previewCGImage);
    */
    
    // set the image in the button
    [self.previewButton setImage:image forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark view management
-(void) viewDidLoad {
    srandom(time(NULL));
    [super viewDidLoad];

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.view.frame = CGRectMake(0, 0, screenSize.height, screenSize.width - 44);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(32, 32, 256, 128);
    [button addTarget:self action:@selector(updatePreview) forControlEvents:UIControlEventTouchUpInside];
    self.previewButton = button;
    [button release];
    [self.view addSubview:self.previewButton];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) dealloc {
    [previewButton release];
    [seedCommand release];
    [super dealloc];
}


@end
