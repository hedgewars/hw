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

#import "PascalImports.h"
#import "CGPointUtils.h"
#import "SDL_uikitview.h"
#import "SDL_uikitappdelegate.h"

#if SDL_IPHONE_KEYBOARD
#import "SDL_keyboard_c.h"
#import "keyinfotable.h"
#import "SDL_uikitwindow.h"
#endif

@implementation SDL_uikitview

// they have to be global variables to allow showControls() to use them
UIButton *attackButton, *menuButton;

-(void) dealloc {
#if SDL_IPHONE_KEYBOARD
	SDL_DelKeyboard(0);
	[textField release];
#endif
	[menuButton release];
	[attackButton release];
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
	// the addTarget parameter for the buttons below is set like that because
	// this object is inherited by SDL_openglesview.m which is the one allocated by SDL.
	// We select this class with [self superclass] and call the selectors with "+" because
	// they are superclass methods 
	self = [super initWithFrame:frame];
	
#if SDL_IPHONE_KEYBOARD
	[self initializeKeyboard];
#endif	

	int i;
	for (i=0; i<MAX_SIMULTANEOUS_TOUCHES; i++) {
        mice[i].id = i;
		mice[i].driverdata = NULL;
		SDL_AddMouse(&mice[i], "Mouse", 0, 0, 1);
	}

	self.multipleTouchEnabled = YES;
	self.exclusiveTouch = YES;
/*
	// custom code
	// the coordinate system is still like in Portrait even though everything is rotated
	attackButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 480, 260, 50)];
	[attackButton setBackgroundImage:[UIImage imageNamed:@"Default.png"] forState:UIControlStateNormal];
	[attackButton setBackgroundImage:[UIImage imageNamed:@"Default.png"] forState:UIControlStateHighlighted];
	[attackButton addTarget:[self superclass] action:@selector(attackButtonPressed) forControlEvents:UIControlEventTouchDown];
	[attackButton addTarget:[self superclass] action:@selector(buttonsReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	//[self addSubview:attackButton];

	menuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 480, 30, 50)];
	[menuButton setBackgroundImage:[UIImage imageNamed:@"Default.png"] forState:UIControlStateNormal];
	[menuButton addTarget:[self superclass] action:@selector(attackButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[menuButton addTarget:[self superclass] action:@selector(buttonsReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	//[self addSubview:menuButton];

	UIButton *walkLeftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
	[walkLeftButton addTarget:[self superclass] action:@selector(walkingLeft) forControlEvents:UIControlEventTouchDown];
	[walkLeftButton addTarget:[self superclass] action:@selector(buttonsReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	[self insertSubview:walkLeftButton atIndex:0];
	[walkLeftButton release];
	
	UIButton *walkRightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 380, 320, 100)];
	[walkRightButton addTarget:[self superclass] action:@selector(walkingRight) forControlEvents:UIControlEventTouchDown];
	[walkRightButton addTarget:[self superclass] action:@selector(buttonsReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	[self insertSubview:walkRightButton atIndex:0];
	[walkRightButton release];

	UIButton *moveDownButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 100, 70, 280)];
	[moveDownButton addTarget:[self superclass] action:@selector(movingDown) forControlEvents:UIControlEventTouchDown];
	[moveDownButton addTarget:[self superclass] action:@selector(buttonsReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	[self insertSubview:moveDownButton atIndex:0];
	[moveDownButton release];
	
	UIButton *moveUpButton = [[UIButton alloc] initWithFrame:CGRectMake(250, 100, 70, 280)];
	[moveUpButton addTarget:[self superclass] action:@selector(movingUp) forControlEvents:UIControlEventTouchDown];
	[moveUpButton addTarget:[self superclass] action:@selector(buttonsReleased) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
	[self insertSubview:moveUpButton atIndex:0];
	[moveUpButton release];
	
	//dummy button used to test chat
	UIButton *chatButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 100, 250, 280)];
	[chatButton addTarget:[self superclass] action:@selector(chatBegin) forControlEvents:UIControlEventTouchDown];
	[self insertSubview:chatButton atIndex:0];
	[chatButton release];
	*/
	return self;
}

#pragma mark -
#pragma mark Exported functions for FreePascal
const char* IPH_getDocumentsPath() {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex: 0];
	return [documentsDirectory UTF8String];
}

void IPH_showControls (void) {
	NSLog(@"Showing controls");
	/*
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	attackButton.frame = CGRectMake(30, 430, 260, 50);
	menuButton.frame = CGRectMake(0, 430, 30, 50);
	[UIView commitAnimations];
	 */
}

#pragma mark -
#pragma mark Superclass methods to call Pascal code
+(void) attackButtonPressed {
	HW_shoot();
}

+(void) buttonsReleased {
	HW_allKeysUp();
}

+(void) walkingLeft {
	HW_walkLeft();
}

+(void) walkingRight {
	HW_walkRight();
}

+(void) movingUp {
	HW_aimUp();
}

+(void) movingDown {
	HW_aimDown();
}

+(void) chatBegin {
	//TODO: implement a UITextScroll and put received chat lines in there
}

#pragma mark -
#pragma mark Custom SDL_UIView input handling
#define kMinimumPinchDelta	50
#define kMinimumGestureLength	10
#define kMaximumVariance	3

// we override default touch input to implement our own gestures
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray *twoTouches;
	UITouch *touch = [touches anyObject];
	
	switch ([touches count]) {
		case 1:
			gestureStartPoint = [touch locationInView:self];
			initialDistanceForPinching = 0;
			switch ([touch tapCount]) {
				case 1:
					
					NSLog(@"X:%d Y:%d", (int)gestureStartPoint.x, (int)gestureStartPoint.y );
					SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].window, 
							      (int)gestureStartPoint.y, 320 - (int)gestureStartPoint.x);
					HW_click();
					break;
				case 2:
					HW_ammoMenu();
					break;
				default:
					break;
			}
			break;
		case 2:
			if (2 == [touch tapCount]) {
				HW_zoomReset();
			}
			
			// pinching
			twoTouches = [touches allObjects];
			UITouch *first = [twoTouches objectAtIndex:0];
			UITouch *second = [twoTouches objectAtIndex:1];
			initialDistanceForPinching = distanceBetweenPoints([first locationInView:self], [second locationInView:self]);
			break;
		default:
			break;
	}

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	initialDistanceForPinching = 0;
	gestureStartPoint.x = 0;
	gestureStartPoint.y = 0;
	HW_allKeysUp();
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// this can happen if the user puts more than 5 touches on the screen at once, or perhaps in other circumstances.
	// Usually (it seems) all active touches are canceled.
	[self touchesEnded:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray *twoTouches;
	CGPoint currentPosition;
	UITouch *touch = [touches anyObject];

	switch ([touches count]) {
		case 1:
			currentPosition = [touch locationInView:self];
			// panning
			SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].window, 
							(int)gestureStartPoint.y, 320 - (int)gestureStartPoint.x);
			// remember that we have x and y inverted
			/* temporarily disabling hog movements for camera panning testing
			CGFloat vertDiff = gestureStartPoint.x - currentPosition.x;
			CGFloat horizDiff = gestureStartPoint.y - currentPosition.y;
			CGFloat deltaX = fabsf(vertDiff);
			CGFloat deltaY = fabsf(horizDiff);
			
			if (deltaY >= kMinimumGestureLength && deltaX <= kMaximumVariance) {
				NSLog(@"Horizontal swipe detected, begX:%f curX:%f", gestureStartPoint.x, currentPosition.x);
				if (horizDiff > 0) HW_walkLeft();
				else HW_walkRight();
			} else if (deltaX >= kMinimumGestureLength && deltaY <= kMaximumVariance){
				NSLog(@"Vertical swipe detected, begY:%f curY:%f", gestureStartPoint.y, currentPosition.y);
				if (vertDiff < 0) HW_aimUp();
				else HW_aimDown();
			}
			*/
			break;
		case 2:
			twoTouches = [touches allObjects];
			UITouch *first = [twoTouches objectAtIndex:0];
			UITouch *second = [twoTouches objectAtIndex:1];
			CGFloat currentDistanceOfPinching = distanceBetweenPoints([first locationInView:self], [second locationInView:self]);
			
			if (0 == initialDistanceForPinching) 
				initialDistanceForPinching = currentDistanceOfPinching;

			if (currentDistanceOfPinching < initialDistanceForPinching + kMinimumPinchDelta)
				HW_zoomOut();
			else if (currentDistanceOfPinching > initialDistanceForPinching + kMinimumPinchDelta)
				HW_zoomIn();

			currentDistanceOfPinching = initialDistanceForPinching;
			break;
		default:
			break;
	}
}

/*
#pragma mark -
#pragma mark Keyboard related functionality
#if SDL_IPHONE_KEYBOARD
// Is the iPhone virtual keyboard visible onscreen? 
- (BOOL)keyboardVisible {
	return keyboardVisible;
}

// Set ourselves up as a UITextFieldDelegate
- (void)initializeKeyboard {
		
	textField = [[[UITextField alloc] initWithFrame: CGRectZero] autorelease];
	textField.delegate = self;
	// placeholder so there is something to delete!
	textField.text = @" ";	
	
	// set UITextInputTrait properties, mostly to defaults
	textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	textField.autocorrectionType = UITextAutocorrectionTypeNo;
	textField.enablesReturnKeyAutomatically = NO;
	textField.keyboardAppearance = UIKeyboardAppearanceDefault;
	textField.keyboardType = UIKeyboardTypeDefault;
	textField.returnKeyType = UIReturnKeyDefault;
	textField.secureTextEntry = NO;	
	
	textField.hidden = YES;
	keyboardVisible = NO;
	// add the UITextField (hidden) to our view
	[self addSubview: textField];
	
	// create our SDL_Keyboard
	SDL_Keyboard keyboard;
	SDL_zero(keyboard);
	SDL_AddKeyboard(&keyboard, 0);
	SDLKey keymap[SDL_NUM_SCANCODES];
	SDL_GetDefaultKeymap(keymap);
	SDL_SetKeymap(0, 0, keymap, SDL_NUM_SCANCODES);
	
}

// reveal onscreen virtual keyboard
- (void)showKeyboard {
	keyboardVisible = YES;
	[textField becomeFirstResponder];
}

// hide onscreen virtual keyboard
- (void)hideKeyboard {
	keyboardVisible = NO;
	[textField resignFirstResponder];
}

// UITextFieldDelegate method.  Invoked when user types something.
- (BOOL)textField:(UITextField *)_textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if ([string length] == 0) {
		// it wants to replace text with nothing, ie a delete
		SDL_SendKeyboardKey( 0, SDL_PRESSED, SDL_SCANCODE_DELETE);
		SDL_SendKeyboardKey( 0, SDL_RELEASED, SDL_SCANCODE_DELETE);
	}
	else {
		// go through all the characters in the string we've been sent and convert them to key presses
		int i;
		for (i=0; i<[string length]; i++) {
			
			unichar c = [string characterAtIndex: i];
			
			Uint16 mod = 0;
			SDL_scancode code;
			
			if (c < 127) {
				// figure out the SDL_scancode and SDL_keymod for this unichar
				code = unicharToUIKeyInfoTable[c].code;
				mod  = unicharToUIKeyInfoTable[c].mod;
			}
			else {
				// we only deal with ASCII right now
				code = SDL_SCANCODE_UNKNOWN;
				mod = 0;
			}
			
			if (mod & KMOD_SHIFT) {
				// If character uses shift, press shift down
				SDL_SendKeyboardKey( 0, SDL_PRESSED, SDL_SCANCODE_LSHIFT);
			}
			// send a keydown and keyup even for the character
			SDL_SendKeyboardKey( 0, SDL_PRESSED, code);
			SDL_SendKeyboardKey( 0, SDL_RELEASED, code);
			if (mod & KMOD_SHIFT) {
				// If character uses shift, press shift back up
				SDL_SendKeyboardKey( 0, SDL_RELEASED, SDL_SCANCODE_LSHIFT);
			}			
		}
	}
	return NO; // don't allow the edit! (keep placeholder text there)
}

// Terminates the editing session
- (BOOL)textFieldShouldReturn:(UITextField*)_textField {
	[self hideKeyboard];
	return YES;
}

#endif
*/
@end
/*
// iPhone keyboard addition functions
#if SDL_IPHONE_KEYBOARD

int SDL_iPhoneKeyboardShow(SDL_Window *window) {
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

int SDL_iPhoneKeyboardHide(SDL_Window *window) {
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

SDL_bool SDL_iPhoneKeyboardIsShown(SDL_Window *window) {
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

int SDL_iPhoneKeyboardToggle(SDL_Window *window) {
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
		if (SDL_iPhoneKeyboardIsShown(window)) {
			SDL_iPhoneKeyboardHide(window);
		}
		else {
			SDL_iPhoneKeyboardShow(window);
		}
		return 0;
	}
}

#else

// stubs, used if compiled without keyboard support

int SDL_iPhoneKeyboardShow(SDL_Window *window) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}

int SDL_iPhoneKeyboardHide(SDL_Window *window) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}

SDL_bool SDL_iPhoneKeyboardIsShown(SDL_Window *window) {
	return 0;
}

int SDL_iPhoneKeyboardToggle(SDL_Window *window) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}

#endif /* SDL_IPHONE_KEYBOARD */
