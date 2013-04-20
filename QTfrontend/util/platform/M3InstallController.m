/*****************************************************************
 M3InstallController.m

 Created by Martin Pilkington on 02/06/2007.

 Copyright (c) 2006-2009 M Cubed Software

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.

 *****************************************************************/

#import "M3InstallController.h"
#import "NSWorkspace_RBAdditions.h"

#import <Foundation/Foundation.h>

@implementation M3InstallController

-(id) init {
    if ((self = [super init])) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ is currently running from a disk image", @"AppName is currently running from a disk image"), appName];
        NSString *body = [NSString stringWithFormat:NSLocalizedString(@"Would you like to install %@ in your applications folder before quitting?", @"Would you like to install App Name in your applications folder before quitting?"), appName];
        alert = [[NSAlert alertWithMessageText:title
                                 defaultButton:NSLocalizedString(@"Install", @"Install")
                               alternateButton:NSLocalizedString(@"Don't Install", @"Don't Install")
                                   otherButton:nil
                     informativeTextWithFormat:body] retain];
        //[alert setShowsSuppressionButton:YES];
    }
    return self;
}

-(void) displayInstaller {
    NSString *imageFilePath = [[[NSWorkspace sharedWorkspace] propertiesForPath:[[NSBundle mainBundle] bundlePath]] objectForKey:NSWorkspace_RBimagefilepath];
    if (imageFilePath && ![imageFilePath isEqualToString:[NSString stringWithFormat:@"/Users/.%@/%@.sparseimage", NSUserName(), NSUserName()]] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"M3DontAskInstallAgain"]) {
        NSInteger returnValue = [alert runModal];
        if (returnValue == NSAlertDefaultReturn) {
            [self installApp];
        }
        if ([NSAlert instancesRespondToSelector:@selector(suppressionButton)])
            if ([[alert performSelector:@selector(suppressionButton)] state] == NSOnState)
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"M3DontAskInstallAgain"];
        }
}

-(void) installApp {
    NSString *appsPath = [[NSString stringWithString:@"/Applications"] stringByAppendingPathComponent:[[[NSBundle mainBundle] bundlePath] lastPathComponent]];
    NSString *userAppsPath = [[[NSString stringWithString:@"~/Applications"] stringByAppendingPathComponent:[[[NSBundle mainBundle] bundlePath] lastPathComponent]] stringByExpandingTildeInPath];
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *currentPath = [[NSBundle mainBundle] bundlePath];
    NSString *finalPath;
    NSError *error = nil;
    BOOL success;

    // Prepare the remove invocation
    SEL removeSelector;
    if ([NSFileManager instancesRespondToSelector:@selector(removeItemAtPath:error:)])
        removeSelector = @selector(removeItemAtPath:error:);
    else
        removeSelector = @selector(removeFileAtPath:handler:);

    NSMethodSignature *removeSignature = [NSFileManager instanceMethodSignatureForSelector:removeSelector];
    NSInvocation *removeInvocation = [NSInvocation invocationWithMethodSignature:removeSignature];
    [removeInvocation setTarget:[NSFileManager defaultManager]];
    [removeInvocation setSelector:removeSelector];

    // Delete the app if already installed
    if ([[NSFileManager defaultManager] fileExistsAtPath:appsPath]) {
        [removeInvocation setArgument:&appsPath atIndex:2];
        [removeInvocation setArgument:&error atIndex:3];
        [removeInvocation invoke];
    }

    // Prepare the copy invocation
    SEL copySelector;
    if ([NSFileManager instancesRespondToSelector:@selector(copyItemAtPath:toPath:error:)])
        copySelector = @selector(copyItemAtPath:toPath:error:);
    else
        copySelector = @selector(copyPath:toPath:handler:);

    NSMethodSignature *copySignature = [NSFileManager instanceMethodSignatureForSelector:copySelector];
    NSInvocation *copyInvocation = [NSInvocation invocationWithMethodSignature:copySignature];

    [copyInvocation setTarget:[NSFileManager defaultManager]];
    [copyInvocation setSelector:copySelector];

    // Copy the app in /Applications
    [copyInvocation setArgument:&currentPath atIndex:2];
    [copyInvocation setArgument:&appsPath atIndex:3];
    [copyInvocation setArgument:&error atIndex:4];
    [copyInvocation invoke];
    [copyInvocation getReturnValue:&success];
    finalPath = @"/Applications";

    // In case something went wrong, let's try again somewhere else
    if (success == NO) {
        // Delete the app if already installed
        if ([[NSFileManager defaultManager] fileExistsAtPath:userAppsPath]) {
            [removeInvocation setArgument:&userAppsPath atIndex:2];
            [removeInvocation invoke];
        }

        // Copy the app in ~/Applications
        [copyInvocation setArgument:&userAppsPath atIndex:3];
        [copyInvocation invoke];
        [copyInvocation getReturnValue:&success];
        finalPath = [[NSString stringWithString:@"~/Applications"] stringByExpandingTildeInPath];
    }

    if (success)
        NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"%@ installed successfully", @"successful installation title"), appName],
              [NSString stringWithFormat:NSLocalizedString(@"%@ was installed in %@", @"successfull installation text"), appName, finalPath],
              NSLocalizedString(@"Ok", @"ok message"), nil, nil);
    else
        NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"Could not install %@", @"installation failure title"), appName],
              NSLocalizedString(@"An error occurred when installing", @"installation failure text"),
              NSLocalizedString(@"Quit", @"exit message"), nil, nil);
}

@end
