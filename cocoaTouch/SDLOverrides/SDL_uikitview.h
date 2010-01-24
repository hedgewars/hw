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
#include "SDL_stdinc.h"
#include "SDL_mouse.h"
#include "SDL_mouse_c.h"
#include "SDL_events.h"

#import "CGPointUtils.h"

#if SDL_IPHONE_MULTIPLE_MICE
#define MAX_SIMULTANEOUS_TOUCHES 5
#else
#define MAX_SIMULTANEOUS_TOUCHES 1
#endif

// constants for telling which input has been received
#define kMinimumPinchDelta	100
#define kMinimumGestureLength	10
#define kMaximumVariance	4

/* *INDENT-OFF* */
//#if SDL_IPHONE_KEYBOARD
//@interface SDL_uikitview : UIView<UITextFieldDelegate> {
//#else
@interface SDL_uikitview : UIView {
//#endif
	SDL_Mouse mice[MAX_SIMULTANEOUS_TOUCHES];
	CGFloat initialDistance;
	CGPoint gestureStartPoint;

#if SDL_IPHONE_KEYBOARD
	UITextField *textField;
	BOOL keyboardVisible;
#endif
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;

// see initWithFrame for why "+"
+(void) attackButtonPressed;
+(void) attackButtonReleased;

@property CGFloat initialDistance;
@property CGPoint gestureStartPoint;

#if SDL_IPHONE_KEYBOARD
- (void)showKeyboard;
- (void)hideKeyboard;
- (void)initializeKeyboard;
@property (readonly) BOOL keyboardVisible;
#endif 

@end
/* *INDENT-ON* */
