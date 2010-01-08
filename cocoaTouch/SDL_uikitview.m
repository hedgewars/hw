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

#include "PascalImports.h"
#import "SDL_uikitview.h"
#import "SDL_uikitappdelegate.h"

#if SDL_IPHONE_KEYBOARD
#import "SDL_keyboard_c.h"
#import "keyinfotable.h"
#import "SDL_uikitwindow.h"
#endif

@implementation SDL_uikitview

@synthesize initialDistance, gestureStartPoint;

- (void)dealloc {
#if SDL_IPHONE_KEYBOARD
	SDL_DelKeyboard(0);
	[textField release];
#endif
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {

	self = [super initWithFrame: frame];
	
#if SDL_IPHONE_KEYBOARD
	[self initializeKeyboard];
#endif	

	int i;
	for (i=0; i<MAX_SIMULTANEOUS_TOUCHES; i++) {
        mice[i].id = i;
		mice[i].driverdata = NULL;
		SDL_AddMouse(&mice[i], "Mouse", 0, 0, 1);
	}
	
	UIButton *attackButton;

	attackButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 90,60)];
	[attackButton setBackgroundImage:[UIImage imageNamed:@"Default.png"] forState:UIControlStateNormal];
	// this object is inherited by SDL_openglesview.m which is the one allocated by SDL.
	// We select this class with [self superclass] and call the selectors with "+" because
	// they are superclass methods 
	[attackButton addTarget:[self superclass] action:@selector(attackButtonPressed) forControlEvents:UIControlEventTouchDown];
	[attackButton addTarget:[self superclass] action:@selector(attackButtonReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	[self insertSubview:attackButton atIndex:10];
	[attackButton release];

	self.multipleTouchEnabled = YES;
			
	return self;
}

#pragma mark -
#pragma mark Superclass methods
+(void) attackButtonPressed {
	HW_shoot();
}

+(void) attackButtonReleased {
	HW_allKeysUp();
}

#pragma mark -
#pragma mark Custom SDL_UIView input handling

// we override default touch input to implement our own gestures
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	/*NSEnumerator *enumerator = [touches objectEnumerator];
	UITouch *touch =(UITouch*)[enumerator nextObject];
	
	/* associate touches with mice, so long as we have slots 
	int i;
	int found = 0;
	for(i=0; touch && i < MAX_SIMULTANEOUS_TOUCHES; i++) {
	
		/* check if this mouse is already tracking a touch 
		if (mice[i].driverdata != NULL) {
			continue;
		}
		/*	
			mouse not associated with anything right now,
			associate the touch with this mouse
		
		found = 1;
		
		/* save old mouse so we can switch back 
		int oldMouse = SDL_SelectMouse(-1);
		
		/* select this slot's mouse 
		SDL_SelectMouse(i);
		CGPoint locationInView = [touch locationInView: self];
		
		/* set driver data to touch object, we'll use touch object later 
		mice[i].driverdata = [touch retain];
		
		/* send moved event 
		SDL_SendMouseMotion(i, 0, locationInView.x, locationInView.y, 0);
		
		/* send mouse down event 
		SDL_SendMouseButton(i, SDL_PRESSED, SDL_BUTTON_LEFT);
		
		/* re-calibrate relative mouse motion 
		SDL_GetRelativeMouseState(i, NULL, NULL);
		
		/* grab next touch 
		touch = (UITouch*)[enumerator nextObject]; 
		
		/* switch back to our old mouse 
		SDL_SelectMouse(oldMouse);
		
	}	*/
	
	UITouch *touch = [touches anyObject];
	gestureStartPoint = [touch locationInView:self];

	// one tap - single click
	if (1 == [touch tapCount] ) {
		//SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].windowID, gestureStartPoint.x, gestureStartPoint.y);
		HW_click();
	}
	
	// two taps - right click
	if (2 == [touch tapCount] ) {
		HW_ammoMenu();
	}
	
	// two taps with two fingers - middle click
	if (2 == [touch tapCount] && 2 == [touches count]) {
		HW_zoomReset();
	}
	
	// two fingers - begin pinching
	if (2 == [touches count]) {
		NSArray *twoTouches = [touches allObjects];
		UITouch *first = [twoTouches objectAtIndex:0];
		UITouch *second = [twoTouches objectAtIndex:1];
		initialDistance = distanceBetweenPoints([first locationInView:self], [second locationInView:self]);
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	initialDistance = 0;
//	NSLog(@"touches ended, sigh");
	
	HW_allKeysUp();
	/*NSEnumerator *enumerator = [touches objectEnumerator];
	UITouch *touch=nil;
	
	while(touch = (UITouch *)[enumerator nextObject]) {
		/* search for the mouse slot associated with this touch 
		int i, found = NO;
		for (i=0; i<MAX_SIMULTANEOUS_TOUCHES && !found; i++) {
			if (mice[i].driverdata == touch) {
				/* found the mouse associate with the touch 
				[(UITouch*)(mice[i].driverdata) release];
				mice[i].driverdata = NULL;
				/* send mouse up 
				SDL_SendMouseButton(i, SDL_RELEASED, SDL_BUTTON_LEFT);
				/* discontinue search for this touch 
				found = YES;
			}
		}
	}*/
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	/*
		this can happen if the user puts more than 5 touches on the screen
		at once, or perhaps in other circumstances.  Usually (it seems)
		all active touches are canceled.
	*/
	[self touchesEnded: touches withEvent: event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint currentPosition = [touch locationInView:self];
	
	CGFloat Xdiff = gestureStartPoint.x - currentPosition.x;
	CGFloat Ydiff = gestureStartPoint.y - currentPosition.y;
	CGFloat deltaX = fabsf(Xdiff);
    CGFloat deltaY = fabsf(Ydiff);
    
	if (deltaX >= kMinimumGestureLength && deltaY <= kMaximumVariance) {
		NSLog(@"Horizontal swipe detected, begX:%f curX:%f", gestureStartPoint.x, currentPosition.x);
		if (Xdiff > 0) HW_walkLeft();
		else HW_walkRight();
    }
    else if (deltaY >= kMinimumGestureLength && deltaX <= kMaximumVariance){
		NSLog(@"Vertical swipe detected, begY:%f curY:%f", gestureStartPoint.y, currentPosition.y);
		if (Ydiff > 0) HW_aimUp();
		else HW_aimDown();
	}
	
	// end pinch detection
	if (2 == [touches count]) {
		NSArray *twoTouches = [touches allObjects];
		UITouch *first = [twoTouches objectAtIndex:0];
		UITouch *second = [twoTouches objectAtIndex:1];
		CGFloat currentDistance = distanceBetweenPoints([first locationInView:self], [second locationInView:self]);
	
		if (0 == initialDistance) 
			initialDistance = currentDistance;
		else if (currentDistance - initialDistance > kMinimumPinchDelta) {
			NSLog(@"Outward pinch detected");
			HW_zoomOut();
		}
		else if (initialDistance - currentDistance > kMinimumPinchDelta) {
			NSLog(@"Inward pinch detected");
			HW_zoomIn();
		}
	}
	
	/*NSEnumerator *enumerator = [touches objectEnumerator];
	 UITouch *touch=nil;while(touch = (UITouch *)[enumerator nextObject]) {
		// try to find the mouse associated with this touch 
		int i, found = NO;
		for (i=0; i<MAX_SIMULTANEOUS_TOUCHES && !found; i++) {
			if (mice[i].driverdata == touch) {
				// found proper mouse 
				CGPoint locationInView = [touch locationInView: self];
				// send moved event 
				SDL_SendMouseMotion(i, 0, locationInView.x, locationInView.y, 0);
				// discontinue search 
				found = YES;
			}
		}
	}*/
}

#pragma mark -
#pragma mark default routines
/*
	---- Keyboard related functionality below this line ----
*/
#if SDL_IPHONE_KEYBOARD

/* Is the iPhone virtual keyboard visible onscreen? */
- (BOOL)keyboardVisible {
	return keyboardVisible;
}

/* Set ourselves up as a UITextFieldDelegate */
- (void)initializeKeyboard {
		
	textField = [[[UITextField alloc] initWithFrame: CGRectZero] autorelease];
	textField.delegate = self;
	/* placeholder so there is something to delete! */
	textField.text = @" ";	
	
	/* set UITextInputTrait properties, mostly to defaults */
	textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	textField.autocorrectionType = UITextAutocorrectionTypeNo;
	textField.enablesReturnKeyAutomatically = NO;
	textField.keyboardAppearance = UIKeyboardAppearanceDefault;
	textField.keyboardType = UIKeyboardTypeDefault;
	textField.returnKeyType = UIReturnKeyDefault;
	textField.secureTextEntry = NO;	
	
	textField.hidden = YES;
	keyboardVisible = NO;
	/* add the UITextField (hidden) to our view */
	[self addSubview: textField];
	
	/* create our SDL_Keyboard */
	SDL_Keyboard keyboard;
	SDL_zero(keyboard);
	SDL_AddKeyboard(&keyboard, 0);
	SDLKey keymap[SDL_NUM_SCANCODES];
	SDL_GetDefaultKeymap(keymap);
	SDL_SetKeymap(0, 0, keymap, SDL_NUM_SCANCODES);
	
}

/* reveal onscreen virtual keyboard */
- (void)showKeyboard {
	keyboardVisible = YES;
	[textField becomeFirstResponder];
}

/* hide onscreen virtual keyboard */
- (void)hideKeyboard {
	keyboardVisible = NO;
	[textField resignFirstResponder];
}

/* UITextFieldDelegate method.  Invoked when user types something. */
- (BOOL)textField:(UITextField *)_textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if ([string length] == 0) {
		/* it wants to replace text with nothing, ie a delete */
		SDL_SendKeyboardKey( 0, SDL_PRESSED, SDL_SCANCODE_DELETE);
		SDL_SendKeyboardKey( 0, SDL_RELEASED, SDL_SCANCODE_DELETE);
	}
	else {
		/* go through all the characters in the string we've been sent
		   and convert them to key presses */
		int i;
		for (i=0; i<[string length]; i++) {
			
			unichar c = [string characterAtIndex: i];
			
			Uint16 mod = 0;
			SDL_scancode code;
			
			if (c < 127) {
				/* figure out the SDL_scancode and SDL_keymod for this unichar */
				code = unicharToUIKeyInfoTable[c].code;
				mod  = unicharToUIKeyInfoTable[c].mod;
			}
			else {
				/* we only deal with ASCII right now */
				code = SDL_SCANCODE_UNKNOWN;
				mod = 0;
			}
			
			if (mod & KMOD_SHIFT) {
				/* If character uses shift, press shift down */
				SDL_SendKeyboardKey( 0, SDL_PRESSED, SDL_SCANCODE_LSHIFT);
			}
			/* send a keydown and keyup even for the character */
			SDL_SendKeyboardKey( 0, SDL_PRESSED, code);
			SDL_SendKeyboardKey( 0, SDL_RELEASED, code);
			if (mod & KMOD_SHIFT) {
				/* If character uses shift, press shift back up */
				SDL_SendKeyboardKey( 0, SDL_RELEASED, SDL_SCANCODE_LSHIFT);
			}			
		}
	}
	return NO; /* don't allow the edit! (keep placeholder text there) */
}

/* Terminates the editing session */
- (BOOL)textFieldShouldReturn:(UITextField*)_textField {
	[self hideKeyboard];
	return YES;
}

#endif

@end

/* iPhone keyboard addition functions */
#if SDL_IPHONE_KEYBOARD

int SDL_iPhoneKeyboardShow(SDL_WindowID windowID) {
	
	SDL_Window *window = SDL_GetWindowFromID(windowID);
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (nil == view) {
		SDL_SetError("Window has no view");
		return -1;
	}
	else {
		[view showKeyboard];
		return 0;
	}
}

int SDL_iPhoneKeyboardHide(SDL_WindowID windowID) {
	
	SDL_Window *window = SDL_GetWindowFromID(windowID);
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}	
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (NULL == view) {
		SDL_SetError("Window has no view");
		return -1;
	}
	else {
		[view hideKeyboard];
		return 0;
	}
}

SDL_bool SDL_iPhoneKeyboardIsShown(SDL_WindowID windowID) {
	
	SDL_Window *window = SDL_GetWindowFromID(windowID);
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}	
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (NULL == view) {
		SDL_SetError("Window has no view");
		return 0;
	}
	else {
		return view.keyboardVisible;
	}
}

int SDL_iPhoneKeyboardToggle(SDL_WindowID windowID) {
	
	SDL_Window *window = SDL_GetWindowFromID(windowID);
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}	
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (NULL == view) {
		SDL_SetError("Window has no view");
		return -1;
	}
	else {
		if (SDL_iPhoneKeyboardIsShown(windowID)) {
			SDL_iPhoneKeyboardHide(windowID);
		}
		else {
			SDL_iPhoneKeyboardShow(windowID);
		}
		return 0;
	}
}

#else

/* stubs, used if compiled without keyboard support */

int SDL_iPhoneKeyboardShow(SDL_WindowID windowID) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}

int SDL_iPhoneKeyboardHide(SDL_WindowID windowID) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}

SDL_bool SDL_iPhoneKeyboardIsShown(SDL_WindowID windowID) {
	return 0;
}

int SDL_iPhoneKeyboardToggle(SDL_WindowID windowID) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}


#endif /* SDL_IPHONE_KEYBOARD */
