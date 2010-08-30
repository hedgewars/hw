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

@implementation MapConfigViewController
@synthesize previewButton, maxHogs, seedCommand, templateFilterCommand, mapGenCommand, mazeSizeCommand, themeCommand, staticMapCommand,
            tableView, maxLabel, sizeLabel, segmentedControl, slider, lastIndexPath, themeArray, mapArray, busy, delegate;


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

-(const uint8_t *)engineProtocol:(NSInteger) port {
    IPaddress ip;
    BOOL serverQuit = NO;
    static uint8_t map[128*32];

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

            [self sendToEngine:self.seedCommand];
            [self sendToEngine:self.templateFilterCommand];
            [self sendToEngine:self.mapGenCommand];
            [self sendToEngine:self.mazeSizeCommand];
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

    // select the port for IPC and launch the preview generation through engineProtocol:
    int port = randomPort();
    const uint8_t *map = [self engineProtocol:port];
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

    // set the preview image (autoreleased) in the button and the maxhog label on the main thread to prevent a leak
    [self performSelectorOnMainThread:@selector(setButtonImage:) withObject:[previewImage makeRoundCornersOfSize:CGSizeMake(12, 12)] waitUntilDone:NO];
    [previewImage release];
    [self performSelectorOnMainThread:@selector(setLabelText:) withObject:[NSString stringWithFormat:@"%d", maxHogs] waitUntilDone:NO];

    // restore functionality of button and remove the spinning wheel on the main thread to prevent a leak
    [self performSelectorOnMainThread:@selector(turnOnWidgets) withObject:nil waitUntilDone:NO];

    [pool release];
    //Invoking this method should be avoided as it does not give your thread a chance to clean up any resources it allocated during its execution.
    //[NSThread exit];

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

-(IBAction) mapButtonPressed {
    playSound(@"clickSound");
    [self updatePreview];
}

-(void) updatePreview {
    // don't generate a new preview while it's already generating one
    if (busy)
        return;

    // generate a seed
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *seed = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    NSString *seedCmd = [[NSString alloc] initWithFormat:@"eseed {%@}", seed];
    [seed release];
    self.seedCommand = seedCmd;
    [seedCmd release];

    NSIndexPath *theIndex;
    if (segmentedControl.selectedSegmentIndex != 1) {
        // remove the current preview and title
        [self.previewButton setImage:nil forState:UIControlStateNormal];
        [self.previewButton setTitle:nil forState:UIControlStateNormal];

        // don't display preview on slower device, too slow and memory hog
        NSString *modelId = modelType();
        if ([modelId hasPrefix:@"iPhone1"] || [modelId hasPrefix:@"iPod1,1"] || [modelId hasPrefix:@"iPod2,1"]) {
            busy = NO;
            [self.previewButton setTitle:NSLocalizedString(@"Preview not available",@"") forState:UIControlStateNormal];
        } else {
            // prevent other events and add an activity while the preview is beign generated
            [self turnOffWidgets];

            // add a very nice spinning wheel
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]
                                                  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            indicator.center = CGPointMake(previewButton.bounds.size.width / 2, previewButton.bounds.size.height / 2);
            indicator.tag = INDICATOR_TAG;
            [indicator startAnimating];
            [self.previewButton addSubview:indicator];
            [indicator release];

            // let's draw in a separate thread so the gui can work; at the end it restore other widgets
            [NSThread detachNewThreadSelector:@selector(drawingThread) toTarget:self withObject:nil];
        }

        theIndex = [NSIndexPath indexPathForRow:(random()%[self.themeArray count]) inSection:0];
    } else {
        theIndex = [NSIndexPath indexPathForRow:(random()%[self.mapArray count]) inSection:0];
    }
    [self.tableView reloadData];
    [self tableView:self.tableView didSelectRowAtIndexPath:theIndex];
    [self.tableView scrollToRowAtIndexPath:theIndex atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

// instead of drawing a random map we load an image; this function is called by didSelectRowAtIndexPath only
-(void) updatePreviewWithMap:(NSInteger) index {
    // change the preview button
    NSString *fileImage = [[NSString alloc] initWithFormat:@"%@/%@/preview.png", MAPS_DIRECTORY(),[self.mapArray objectAtIndex:index]];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:fileImage];
    [fileImage release];
    [self.previewButton setImage:[image makeRoundCornersOfSize:CGSizeMake(12, 12)] forState:UIControlStateNormal];
    [image release];

    // update label
    maxHogs = 18;
    NSString *fileCfg = [[NSString alloc] initWithFormat:@"%@/%@/map.cfg", MAPS_DIRECTORY(),[self.mapArray objectAtIndex:index]];
    NSString *contents = [[NSString alloc] initWithContentsOfFile:fileCfg encoding:NSUTF8StringEncoding error:NULL];
    [fileCfg release];
    NSArray *split = [contents componentsSeparatedByString:@"\n"];
    [contents release];

    // set the theme and map here
    self.themeCommand = [NSString stringWithFormat:@"etheme %@", [split objectAtIndex:0]];
    self.staticMapCommand = [NSString stringWithFormat:@"emap %@", [self.mapArray objectAtIndex:index]];

    // if the number is not set we keep 18 standard;
    // sometimes it's not set but there are trailing characters, we get around them with the second equation
    if ([split count] > 1 && [[split objectAtIndex:1] intValue] > 0)
        maxHogs = [[split objectAtIndex:1] intValue];
    NSString *max = [[NSString alloc] initWithFormat:@"%d",maxHogs];
    self.maxLabel.text = max;
    [max release];
}

-(void) turnOffWidgets {
    busy = YES;
    self.previewButton.alpha = 0.5f;
    self.previewButton.enabled = NO;
    self.maxLabel.text = @"...";
    self.segmentedControl.enabled = NO;
    self.slider.enabled = NO;
}

-(void) turnOnWidgets {
    self.previewButton.alpha = 1.0f;
    self.previewButton.enabled = YES;
    self.segmentedControl.enabled = YES;
    self.slider.enabled = YES;
    busy = NO;

    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self.previewButton viewWithTag:INDICATOR_TAG];
    if (indicator) {
        [indicator stopAnimating];
        [indicator removeFromSuperview];
    }
}

-(void) setLabelText:(NSString *)str {
    self.maxLabel.text = str;
}

-(void) setButtonImage:(UIImage *)img {
    [self.previewButton setBackgroundImage:img forState:UIControlStateNormal];
}

-(void) restoreBackgroundImage {
    // white rounded rectangle as background image for previewButton
    UIGraphicsBeginImageContext(CGSizeMake(256,128));
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context,CGRectMake(0,0,256,128));

    UIGraphicsPopContext();
    UIImage *bkgImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.previewButton setBackgroundImage:[bkgImg makeRoundCornersOfSize:CGSizeMake(12, 12)] forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger) section {
    if (self.segmentedControl.selectedSegmentIndex != 1)
        return [themeArray count];
    else
        return [mapArray count];
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = [indexPath row];

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        cell.textLabel.textColor = UICOLOR_HW_YELLOW_TEXT;

    if (self.segmentedControl.selectedSegmentIndex != 1) {
        // the % prevents a strange bug that occurs sporadically
        NSString *themeName = [self.themeArray objectAtIndex:row % [self.themeArray count]];
        cell.textLabel.text = themeName;
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/icon.png",THEMES_DIRECTORY(),themeName]];
        cell.imageView.image = image;
        [image release];
    } else {
        cell.textLabel.text = [self.mapArray objectAtIndex:row];
        cell.imageView.image = nil;
    }

    if (row == [self.lastIndexPath row]) {
        UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
        cell.accessoryView = checkbox;
        [checkbox release];
    } else
        cell.accessoryView = nil;

    cell.backgroundColor = [UIColor blackColor];
    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;

    if (newRow != oldRow) {
        if (self.segmentedControl.selectedSegmentIndex != 1) {
            NSString *theme = [self.themeArray objectAtIndex:newRow];
            self.themeCommand = [NSString stringWithFormat:@"etheme %@", theme];
        } else {
            // theme and map are set in the function below
            [self updatePreviewWithMap:newRow];
        }

        UITableViewCell *newCell = [aTableView cellForRowAtIndexPath:indexPath];
        UIImageView *checkbox = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"checkbox.png"]];
        newCell.accessoryView = checkbox;
        [checkbox release];
        UITableViewCell *oldCell = [aTableView cellForRowAtIndexPath:self.lastIndexPath];
        oldCell.accessoryView = nil;

        self.lastIndexPath = indexPath;
        [aTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark slider & segmentedControl
// this updates the label and the command keys when the slider is moved, depending of the selection in segmentedControl
// no methods are called by this routine and you can pass nil to it
-(IBAction) sliderChanged:(id) sender {
    NSString *labelText;
    NSString *templateCommand;
    NSString *mazeCommand;

    switch ((int)(self.slider.value*100)) {
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
            labelText = nil;
            templateCommand = nil;
            mazeCommand = nil;
            break;
    }

    self.sizeLabel.text = labelText;
    self.templateFilterCommand = templateCommand;
    self.mazeSizeCommand = mazeCommand;
}

// update preview (if not busy and if its value really changed) as soon as the user lifts its finger up
-(IBAction) sliderEndedChanging:(id) sender {
    int num = (int) (self.slider.value * 100);
    if (oldValue != num) {
        [self updatePreview];
        oldValue = num;
    }
    playSound(@"clickSound");
}

// perform actions based on the activated section, then call updatePreview to visually update the selection
// updatePreview will call didSelectRowAtIndexPath which will call the right update routine)
// and if necessary update the table with a slide animation
-(IBAction) segmentedControlChanged:(id) sender {
    NSString *mapgen, *staticmap;
    NSInteger newPage = self.segmentedControl.selectedSegmentIndex;

    playSound(@"selSound");
    switch (newPage) {
        case 0: // Random
            mapgen = @"e$mapgen 0";
            staticmap = @"";
            [self sliderChanged:nil];
            self.slider.enabled = YES;
            break;

        case 1: // Map
            mapgen = @"e$mapgen 0";
            // dummy value, everything is set by -updatePreview -> -didSelectRowAtIndexPath -> -updatePreviewWithMap
            staticmap = @"map Bamboo";
            self.slider.enabled = NO;
            self.sizeLabel.text = NSLocalizedString(@"No filter",@"");
            [self restoreBackgroundImage];
            break;

        case 2: // Maze
            mapgen = @"e$mapgen 1";
            staticmap = @"";
            [self sliderChanged:nil];
            self.slider.enabled = YES;
            break;

        default:
            mapgen = nil;
            staticmap = nil;
            break;
    }
    self.mapGenCommand = mapgen;
    self.staticMapCommand = staticmap;
    [self updatePreview];

    // nice animation for updating the table when appropriate (on iphone)
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        if (((oldPage == 0 || oldPage == 2) && newPage == 1) ||
            (oldPage == 1 && (newPage == 0 || newPage == 2))) {
            [UIView beginAnimations:@"moving out table" context:NULL];
            self.tableView.frame = CGRectMake(480, 0, 185, 276);
            [UIView commitAnimations];
            [self performSelector:@selector(moveTable) withObject:nil afterDelay:0.2];
        }
    oldPage = newPage;
}

// update data when table is not visible and then show it
-(void) moveTable {
    [self.tableView reloadData];

    [UIView beginAnimations:@"moving in table" context:NULL];
    self.tableView.frame = CGRectMake(295, 0, 185, 276);
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark view management
-(void) viewDidLoad {
    [super viewDidLoad];

    srandom(time(NULL));

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.view.frame = CGRectMake(0, 0, screenSize.height, screenSize.width - 44);

    // themes.cfg contains all the user-selectable themes
    NSString *string = [[NSString alloc] initWithContentsOfFile:[THEMES_DIRECTORY() stringByAppendingString:@"/themes.cfg"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:[string componentsSeparatedByString:@"\n"]];
    [string release];
    // remove a trailing "" element
    [array removeLastObject];
    self.themeArray = array;
    [array release];
    self.mapArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:MAPS_DIRECTORY() error:NULL];

    busy = NO;

    // draw a white background
    [self restoreBackgroundImage];

    // initialize some "default" values
    self.sizeLabel.text = NSLocalizedString(@"All",@"");
    self.slider.value = 0.05f;

    // select a map at first because it's faster - done in IB
    //self.segmentedControl.selectedSegmentIndex = 1;
    if (self.segmentedControl.selectedSegmentIndex == 1) {
        self.slider.enabled = NO;
        self.sizeLabel.text = NSLocalizedString(@"No filter",@"");
    }

    self.templateFilterCommand = @"e$template_filter 0";
    self.mazeSizeCommand = @"e$maze_size 0";
    self.mapGenCommand = @"e$mapgen 0";
    self.staticMapCommand = @"";

    self.lastIndexPath = [NSIndexPath indexPathForRow:-1 inSection:0];

    oldValue = 5;
    oldPage = 0;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.tableView setBackgroundView:nil];
        self.view.backgroundColor = [UIColor clearColor];
        self.tableView.separatorColor = UICOLOR_HW_YELLOW_BODER;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.rowHeight = 45;
    }
}

-(void) viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    [self updatePreview];
}

#pragma mark -
#pragma mark delegate functions for iPad
-(IBAction) buttonPressed:(id) sender {
    if (self.delegate != nil && [delegate respondsToSelector:@selector(buttonPressed:)])
        [self.delegate buttonPressed:(UIButton *)sender];
}

#pragma mark -
-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    //[previewButton setImage:nil forState:UIControlStateNormal];
    MSG_MEMCLEAN();
}

-(void) viewDidUnload {
    self.delegate = nil;
    
    self.previewButton = nil;
    self.seedCommand = nil;
    self.templateFilterCommand = nil;
    self.mapGenCommand = nil;
    self.mazeSizeCommand = nil;
    self.themeCommand = nil;
    self.staticMapCommand = nil;

    self.previewButton = nil;
    self.tableView = nil;
    self.maxLabel = nil;
    self.sizeLabel = nil;
    self.segmentedControl = nil;
    self.slider = nil;

    self.lastIndexPath = nil;
    self.themeArray = nil;
    self.mapArray = nil;

    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    self.delegate = nil;
    
    [seedCommand release];
    [templateFilterCommand release];
    [mapGenCommand release];
    [mazeSizeCommand release];
    [themeCommand release];
    [staticMapCommand release];

    [previewButton release];
    [tableView release];
    [maxLabel release];
    [sizeLabel release];
    [segmentedControl release];
    [slider release];

    [lastIndexPath release];
    [themeArray release];
    [mapArray release];

    [super dealloc];
}


@end
