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
 * File created on 26/09/2010.
 */


#import "MapPreviewButtonView.h"
#import "MapConfigViewController.h"
#import "UIImageExtra.h"
#import <pthread.h>

#define INDICATOR_TAG 7654

@implementation MapPreviewButtonView
@synthesize delegate;

-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        delegate = nil;
        [self setBackgroundImageRounded:[UIImage whiteImage:frame.size] forState:UIControlStateNormal];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        delegate = nil;
        [self setBackgroundImageRounded:[UIImage whiteImage:self.frame.size] forState:UIControlStateNormal];
    }
    return self;
}

-(void) dealloc {
    self.delegate = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark image wrappers
-(void) setBackgroundImageRounded:(UIImage *)image forState:(UIControlState)state {
    [self setBackgroundImage:[image makeRoundCornersOfSize:CGSizeMake(12, 12)] forState:UIControlStateNormal];    
}

-(void) setImageRounded:(UIImage *)image forState:(UIControlState)state {
    [self setImage:[image makeRoundCornersOfSize:CGSizeMake(12, 12)] forState:UIControlStateNormal];    
}

-(void) setImageRoundedForNormalState:(UIImage *)image {
    [self setImageRounded:image forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark preview 
-(int) sendToEngine:(NSString *)string {
    unsigned char length = [string length];

    SDLNet_TCP_Send(csd, &length, 1);
    return SDLNet_TCP_Send(csd, [string UTF8String], length);
}

-(const uint8_t *)engineProtocol {
    IPaddress ip;
    BOOL serverQuit = NO;
    static uint8_t map[128*32];
    int port = randomPort();

    if (SDLNet_Init() < 0) {
        DLog(@"SDLNet_Init: %s", SDLNet_GetError());
        serverQuit = YES;
    }

    // Resolving the host using NULL make network interface to listen
    if (SDLNet_ResolveHost(&ip, NULL, port) < 0) {
        DLog(@"SDLNet_ResolveHost: %s\n", SDLNet_GetError());
        serverQuit = YES;
    }

    // Open a connection with the IP provided (listen on the host's port)
    if (!(sd = SDLNet_TCP_Open(&ip))) {
        DLog(@"SDLNet_TCP_Open: %s %\n", SDLNet_GetError(), port);
        serverQuit = YES;
    }

    // launch the preview here so that we're sure the tcp channel is open
    pthread_t thread_id;
    pthread_create(&thread_id, NULL, (void *)GenLandPreview, (void *)port);
    pthread_detach(thread_id);

    DLog(@"Waiting for a client on port %d", port);
    while (!serverQuit) {
        /* This check the sd if there is a pending connection.
         * If there is one, accept that, and open a new socket for communicating */
        csd = SDLNet_TCP_Accept(sd);
        if (NULL != csd) {
            DLog(@"Client found");

            NSDictionary *dictForEngine = [self getDataForEngine];
            [self sendToEngine:[dictForEngine objectForKey:@"seedCommand"]];
            [self sendToEngine:[dictForEngine objectForKey:@"templateFilterCommand"]];
            [self sendToEngine:[dictForEngine objectForKey:@"mapGenCommand"]];
            [self sendToEngine:[dictForEngine objectForKey:@"mazeSizeCommand"]];
            [self sendToEngine:@"!"];

            memset(map, 0, 128*32);
            SDLNet_TCP_Recv(csd, map, 128*32);
            SDLNet_TCP_Recv(csd, &maxHogs, sizeof(uint8_t));

            SDLNet_TCP_Close(csd);
            serverQuit = YES;
        }
    }

    SDLNet_TCP_Close(sd);
    SDLNet_Quit();
    return map;
}

-(void) drawingThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    const uint8_t *map = [self engineProtocol];
    uint8_t mapExp[128*32*8];

    // draw the buffer (1 pixel per component, 0= transparent 1= color)
    int k = 0;
    for (int i = 0; i < 32*128; i++) {
        unsigned char byte = map[i];
        for (int j = 0; j < 8; j++) {
            // select the color based on the leftmost bit
            if ((byte & 0x80) != 0)
                mapExp[k] = 100;
            else
                mapExp[k] = 255;
            // shift to next bit
            byte <<= 1;
            k++;
        }
    }
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapImage = CGBitmapContextCreate(mapExp, 256, 128, 8, 256, colorspace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorspace);

    CGImageRef previewCGImage = CGBitmapContextCreateImage(bitmapImage);
    CGContextRelease(bitmapImage);
    UIImage *previewImage = [[UIImage alloc] initWithCGImage:previewCGImage];
    CGImageRelease(previewCGImage);
    previewCGImage = nil;

    // all these are performed on the main thread to prevent a leak
    [self performSelectorOnMainThread:@selector(setImageRoundedForNormalState:)
                           withObject:previewImage
                        waitUntilDone:NO];
    [previewImage release];
    [self performSelectorOnMainThread:@selector(setLabelText:)
                           withObject:[NSString stringWithFormat:@"%d", maxHogs]
                        waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(turnOnWidgets)
                           withObject:nil
                        waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(removeIndicator)
                           withObject:nil
                        waitUntilDone:NO];
    
    [pool release];

    /*
    // http://developer.apple.com/mac/library/qa/qa2001/qa1037.html
    UIGraphicsBeginImageContext(CGSizeMake(256,128));
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextSetRGBFillColor(context, 0.5, 0.5, 0.7, 1.0);
    CGContextFillRect(context,CGRectMake(xc,yc,1,1));
    UIGraphicsPopContext();
    UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    */
}

-(void) updatePreviewWithSeed:(NSString *)seed {
    // remove the current preview and title
    [self setImage:nil forState:UIControlStateNormal];
    [self setTitle:nil forState:UIControlStateNormal];
    
    // don't display preview on slower device, too slow and memory hog
    if (IS_NOT_POWERFUL()) {
        [self setTitle:NSLocalizedString(@"Preview not available",@"") forState:UIControlStateNormal];
        [self turnOnWidgets];
    } else {        
        // add a very nice spinning wheel
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]
                                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        indicator.tag = INDICATOR_TAG;
        [indicator startAnimating];
        [self addSubview:indicator];
        [indicator release];
        
        // let's draw in a separate thread so the gui can work; at the end it restore other widgets
        [NSThread detachNewThreadSelector:@selector(drawingThread) toTarget:self withObject:nil];
    }
}

-(void) updatePreviewWithFile:(NSString *)filePath {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:filePath];
    [self setImageRounded:image forState:UIControlStateNormal];
    [image release];
}

-(void) removeIndicator {
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self viewWithTag:INDICATOR_TAG];
    if (indicator) {
        [indicator stopAnimating];
        [indicator removeFromSuperview];
    }
}

#pragma mark -
#pragma mark delegate
-(void) turnOnWidgets {
    [self.delegate turnOnWidgets];
}

-(void) setLabelText:(NSString *)string {
    [self.delegate setLabelText:string];
}

-(NSDictionary *)getDataForEngine {
    return [self.delegate getDataForEngine];
}

@end
