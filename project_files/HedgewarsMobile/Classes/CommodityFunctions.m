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
 * File created on 08/04/2010.
 */


#import "CommodityFunctions.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <QuartzCore/QuartzCore.h>
#import "AudioToolbox/AudioToolbox.h"
#import "PascalImports.h"

BOOL inline rotationManager (UIInterfaceOrientation interfaceOrientation) {
    if (IS_IPAD())
        return (interfaceOrientation == UIInterfaceOrientationLandscapeRight) ||
               (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
    else
        return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

NSInteger inline randomPort () {
    srandom(time(NULL));
    NSInteger res = (random() % 64511) + 1024;
    return (res == DEFAULT_NETGAME_PORT) ? randomPort() : res;
}

void popError (const char *title, const char *message) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithUTF8String:title]
                                                    message:[NSString stringWithUTF8String:message]
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

// by http://landonf.bikemonkey.org/code/iphone/Determining_Available_Memory.20081203.html
void print_free_memory () {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);

    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        DLog(@"Failed to fetch vm statistics");

    /* Stats in bytes */
    natural_t mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    DLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);
}

BOOL inline isApplePhone () {
    return (IS_IPAD() == NO);
}

NSString *modelType () {
    size_t size;
    // set 'oldp' parameter to NULL to get the size of the data returned so we can allocate appropriate amount of space
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = (char *)malloc(sizeof(char) * size);
    // get the platform name
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *modelId = [NSString stringWithUTF8String:name];
    free(name);

    return modelId;
}

void playSound (NSString *snd) {
    //Get the filename of the sound file:
    NSString *path = [NSString stringWithFormat:@"%@/%@.wav",[[NSBundle mainBundle] resourcePath],snd];
    
    //declare a system sound id
    SystemSoundID soundID;

    //Get a URL for the sound file
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];

    //Use audio sevices to create the sound
    AudioServicesCreateSystemSoundID((CFURLRef)filePath, &soundID);

    //Use audio services to play the sound
    AudioServicesPlaySystemSound(soundID);
}

NSArray inline *getAvailableColors (void) {
    return [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:0x3376E9],     // bluette
                                     [NSNumber numberWithUnsignedInt:0x3e9321],     // greeeen
                                     [NSNumber numberWithUnsignedInt:0xa23dbb],     // violett
                                     [NSNumber numberWithUnsignedInt:0xff9329],     // oranngy
                                     [NSNumber numberWithUnsignedInt:0xdd0000],     // reddish
                                     [NSNumber numberWithUnsignedInt:0x737373],     // graaaay
                                     [NSNumber numberWithUnsignedInt:0x00FFFF],     // cyannnn  
                                     [NSNumber numberWithUnsignedInt:0xFF8888],     // peachyj
                                     nil];
}

UILabel *createBlueLabel (NSString *title, CGRect frame) {
    return createLabelWithParams(title, frame, 1.5f, UICOLOR_HW_YELLOW_BODER, UICOLOR_HW_DARKBLUE);
}

UILabel *createLabelWithParams (NSString *title, CGRect frame, CGFloat borderWidth, UIColor *borderColor, UIColor *backgroundColor) {
    UILabel *theLabel = [[UILabel alloc] initWithFrame:frame];
    theLabel.backgroundColor = backgroundColor;

    if (title != nil) {
        theLabel.text = title;
        theLabel.textColor = UICOLOR_HW_YELLOW_TEXT;
        theLabel.textAlignment = UITextAlignmentCenter;
        theLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]*80/100];
    }
    
    [theLabel.layer setBorderWidth:borderWidth];
    [theLabel.layer setBorderColor:borderColor.CGColor];
    [theLabel.layer setCornerRadius:8.0f];
    [theLabel.layer setMasksToBounds:YES];
    
    return theLabel;
}

// this routine checks for the PNG size without loading it in memory
// https://github.com/steipete/PSFramework/blob/master/PSFramework%20Version%200.3/PhotoshopFramework/PSMetaDataFunctions.m
CGSize PSPNGSizeFromMetaData (NSString *aFileName) {
    // File Name to C String.
    const char *fileName = [aFileName UTF8String];
    // source file
    FILE *infile = fopen(fileName, "rb");
    if (infile == NULL) {
        DLog(@"Can't open the file: %@", aFileName);
        return CGSizeZero;
    }

    // Bytes Buffer.
    unsigned char buffer[30];
    // Grab Only First Bytes.
    fread(buffer, 1, 30, infile);
    // Close File.
    fclose(infile);

    // PNG Signature.
    unsigned char png_signature[8] = {137, 80, 78, 71, 13, 10, 26, 10};

    // Compare File signature.
    if ((int)(memcmp(&buffer[0], &png_signature[0], 8))) {
        DLog(@"The file (%@) is not a PNG file", aFileName);
        return CGSizeZero;
    }

    // Calc Sizes. Isolate only four bytes of each size (width, height).
    int width[4];
    int height[4];
    for (int d = 16; d < (16 + 4); d++) {
        width[d-16] = buffer[d];
        height[d-16] = buffer[d+4];
    }

    // Convert bytes to Long (Integer)
    long resultWidth = (width[0] << (int)24) | (width[1] << (int)16) | (width[2] << (int)8) | width[3];
    long resultHeight = (height[0] << (int)24) | (height[1] << (int)16) | (height[2] << (int)8) | height[3];

    // Return Size.
    return CGSizeMake(resultWidth,resultHeight);
}
