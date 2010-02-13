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

@class MainMenuViewController;

@interface SDLUIKitDelegate:NSObject <UIApplicationDelegate> {
	SDL_Window *window;
	UIWindow *uiwindow;
	MainMenuViewController *viewController;
}

@property (readwrite, assign) SDL_Window *window;
@property (readwrite, retain) UIWindow *uiwindow;
@property (nonatomic, retain) MainMenuViewController *viewController;

+(SDLUIKitDelegate *)sharedAppDelegate;
-(NSString *)dataFilePath:(NSString *)fileName;
-(void) startSDLgame;

@end
