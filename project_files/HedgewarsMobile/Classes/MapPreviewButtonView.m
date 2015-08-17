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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import "MapPreviewButtonView.h"
#import <pthread.h>
#import <QuartzCore/QuartzCore.h>


#define INDICATOR_TAG 7654

@interface MapPreviewButtonView ()
@property (nonatomic) int port;
@end

@implementation MapPreviewButtonView
@synthesize delegate;

-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        delegate = nil;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 12;
    }
    return self;
}

-(void) dealloc {
    self.delegate = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark image wrappers
-(void) setImageRounded:(UIImage *)image forState:(UIControlState)controlState {
    [self setImage:[image makeRoundCornersOfSize:CGSizeMake(12, 12)] forState:controlState];
}

-(void) setImageRounded:(UIImage *)image {
    [self setImageRounded:image forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark preview
-(int) sendToEngine:(NSString *)string {
    unsigned char length = [string length];

    SDLNet_TCP_Send(csd, &length, 1);
    return SDLNet_TCP_Send(csd, [string UTF8String], length);
}

-(void) engineProtocol:(uint8_t *)unpackedMap {
    IPaddress ip;
    BOOL serverQuit = NO;
    uint8_t packedMap[128*32];
    self.port = [HWUtils randomPort];

    if (SDLNet_Init() < 0) {
        DLog(@"SDLNet_Init: %s", SDLNet_GetError());
        serverQuit = YES;
    }

    // Resolving the host using NULL make network interface to listen
    if (SDLNet_ResolveHost(&ip, NULL, self.port) < 0) {
        DLog(@"SDLNet_ResolveHost: %s\n", SDLNet_GetError());
        serverQuit = YES;
    }

    // Open a connection with the IP provided (listen on the host's port)
    if (!(sd = SDLNet_TCP_Open(&ip))) {
        DLog(@"SDLNet_TCP_Open: %s %d\n", SDLNet_GetError(), self.port);
        serverQuit = YES;
    }

    // launch the preview in background here so that we're sure the tcp channel is open
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSString *ipcString = [[NSString alloc] initWithFormat:@"%d", self.port];
        NSString *documentsDirectory = DOCUMENTS_FOLDER();
        
        NSMutableArray *gameParameters = [[NSMutableArray alloc] initWithObjects:
                                          @"--internal",
                                          @"--port", ipcString,
                                          @"--user-prefix", documentsDirectory,
                                          @"--landpreview",
                                          nil];
        [ipcString release];
        
        int argc = [gameParameters count];
        const char **argv = (const char **)malloc(sizeof(const char*)*argc);
        for (int i = 0; i < argc; i++)
            argv[i] = strdup([[gameParameters objectAtIndex:i] UTF8String]);
        [gameParameters release];
        
        RunEngine(argc, argv);
        
        // cleanup
        for (int i = 0; i < argc; i++)
            free((void *)argv[i]);
        free(argv);
    });
    
    DLog(@"Waiting for a client on port %d", self.port);
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

            memset(packedMap, 0, 128*32);
            SDLNet_TCP_Recv(csd, packedMap, 128*32);
            SDLNet_TCP_Recv(csd, &maxHogs, sizeof(uint8_t));

            SDLNet_TCP_Close(csd);
            serverQuit = YES;
        }
    }
    [HWUtils freePort:self.port];
    SDLNet_TCP_Close(sd);
    SDLNet_Quit();

    // spread the packed bits in an array of bytes (one pixel per element, 0= transparent 1= color)
    int k = 0;
    memset(unpackedMap, 255, 128*32*8);     // 255 is white
    for (int i = 0; i < 32*128; i++) {
        for (int j = 7; j >= 0; j--) {
            if (((packedMap[i] >> j) & 0x01) != 0)
                unpackedMap[k] = 170;       // level of gray [0-255]
            k++;
        }
    }
    return;
}

-(void) drawingThread {
    @autoreleasepool {
    
    uint8_t unpackedMap[128*32*8];
    [self engineProtocol:unpackedMap];

    // http://developer.apple.com/mac/library/qa/qa2001/qa1037.html
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapImage = CGBitmapContextCreate(unpackedMap, 256, 128, 8, 256, colorspace, (CGBitmapInfo)kCGImageAlphaNone);
    CGColorSpaceRelease(colorspace);

    CGImageRef previewCGImage = CGBitmapContextCreateImage(bitmapImage);
    CGContextRelease(bitmapImage);
    UIImage *previewImage = [[UIImage alloc] initWithCGImage:previewCGImage];
    CGImageRelease(previewCGImage);

    // all these are performed on the main thread to prevent a leak
    [self performSelectorOnMainThread:@selector(setImageRounded:)
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
    
    }
}

-(void) updatePreviewWithSeed:(NSString *)seed {
    // remove the current preview and title
    [self setImage:nil forState:UIControlStateNormal];
    [self setTitle:nil forState:UIControlStateNormal];

    // don't display preview on slower device, too slow and memory hog
    if (IS_NOT_POWERFUL([HWUtils modelType])) {
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
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 12;
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
    if ([self.delegate respondsToSelector:@selector(turnOnWidgets)])
        [self.delegate turnOnWidgets];
}

-(void) setLabelText:(NSString *)string {
    if ([self.delegate respondsToSelector:@selector(setMaxLabelText:)])
        [self.delegate setMaxLabelText:string];
}

-(NSDictionary *)getDataForEngine {
    if ([self.delegate respondsToSelector:@selector(getDataForEngine)])
        return [self.delegate getDataForEngine];
    return nil;
}

@end
