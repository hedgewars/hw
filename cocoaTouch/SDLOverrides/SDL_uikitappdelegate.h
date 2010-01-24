/*
    SDL - Simple DirectMedia Layer
    Copyright (C) 1997-2009 Sam Lantinga

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

    Sam Lantinga, mods for Hedgewars by Vittorio Giovara
    slouken@libsdl.org, vittorio.giovara@gmail.com
*/

#import <UIKit/UIKit.h>
#import "SDL_video.h"

@interface SDLUIKitDelegate:NSObject<UIApplicationDelegate> {
	UIWindow *window;
	SDL_WindowID windowID;
	UITabBarController *controller;
}

// the outlets are set in MainWindow.xib
@property (readwrite, retain) IBOutlet UIWindow *window;
@property (readwrite, assign) SDL_WindowID windowID;
@property (nonatomic, retain) IBOutlet UITabBarController *controller;

+(SDLUIKitDelegate *)sharedAppDelegate;
-(NSString *)dataFilePath:(NSString *)fileName;
-(void) startSDLgame;

@end
