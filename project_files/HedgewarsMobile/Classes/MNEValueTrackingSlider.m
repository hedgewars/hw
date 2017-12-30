//
// MNEValueTrackingSlider
//
// Copyright 2012 Michael Neuwert
// "You can use the code in your own project and modify it as you like."
// http://blog.neuwert-media.com/2012/04/customized-uislider-with-visual-value-tracking/
//


#import "MNEValueTrackingSlider.h"

#pragma mark -
#pragma mark Private UIView subclass rendering the popup showing slider value
@interface SliderValuePopupView : UIView
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) float arrowOffset;
@end

@implementation SliderValuePopupView

@synthesize font = _font;
@synthesize text = _text;
@synthesize arrowOffset = _arrowOffset;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont boldSystemFontOfSize:18];
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Create the path for the rounded rectangle
    CGRect roundedRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, floorf(self.bounds.size.height * 0.8));
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:6.0];
    roundedRectPath.lineWidth = 2.0f;

    // Create the arrow path
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    /*
    // Make sure the arrow offset is nice
    if (-self.arrowOffset + 1 > CGRectGetMidX(self.bounds) / 2)
        self.arrowOffset = -CGRectGetMidX(self.bounds) / 2 + 1;
    if (self.arrowOffset > CGRectGetMidX(self.bounds) / 2)
        self.arrowOffset = CGRectGetMidX(self.bounds) / 2 -1;
     */

    CGFloat midX = CGRectGetMidX(self.bounds) + self.arrowOffset;
    CGPoint p0 = CGPointMake(midX, CGRectGetMaxY(self.bounds));
    [arrowPath moveToPoint:p0];
    [arrowPath addLineToPoint:CGPointMake((midX - 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath addLineToPoint:CGPointMake((midX + 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath closePath];

    // Attach the arrow path to the rounded rect
    [roundedRectPath appendPath:arrowPath];

    // Color various sections
    [[UIColor blackColor] setFill];
    [roundedRectPath fill];
    [[UIColor whiteColor] setStroke];
    [roundedRectPath stroke];
    [[UIColor whiteColor] setFill];
    [arrowPath fill];

    // Draw the text
    if (self.text) {
        [[UIColor lightYellowColor] set];
        CGSize s = [_text sizeWithFont:self.font];
        CGFloat yOffset = (roundedRect.size.height - s.height) / 2;
        CGRect textRect = CGRectMake(roundedRect.origin.x, yOffset, roundedRect.size.width, s.height);

        [_text drawInRect:textRect
                 withFont:self.font
            lineBreakMode:UILineBreakModeWordWrap
                alignment:NSTextAlignmentCenter];
    }
}

@end

#pragma mark -
#pragma mark MNEValueTrackingSlider implementations
@implementation MNEValueTrackingSlider

@synthesize thumbRect, textValue;

#pragma mark Private methods

- (void)_constructSlider {
    valuePopupView = [[SliderValuePopupView alloc] initWithFrame:CGRectZero];
    valuePopupView.backgroundColor = [UIColor clearColor];
    valuePopupView.alpha = 0.0;
    [self addSubview:valuePopupView];
}

- (void)_fadePopupViewInAndOut:(BOOL)aFadeIn {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    if (aFadeIn) {
        valuePopupView.alpha = 1.0;
    } else {
        valuePopupView.alpha = 0.0;
    }
    [UIView commitAnimations];
}

- (void)_positionAndUpdatePopupView {
    CGRect _thumbRect = self.thumbRect;
    CGRect popupRect = CGRectOffset(_thumbRect, 0, -floorf(_thumbRect.size.height * 1.5));
    // (-100, -15) determines the size of the the rect
    popupRect = CGRectInset(popupRect, -100, -15);

    // this prevents drawing the popup outside the slider view
    if (popupRect.origin.x < -self.frame.origin.x+5)
        popupRect.origin.x = -self.frame.origin.x+5;
    else if (popupRect.origin.x > self.superview.frame.size.width - popupRect.size.width - self.frame.origin.x - 5)
        popupRect.origin.x = self.superview.frame.size.width - popupRect.size.width - self.frame.origin.x - 5;
    //else if (CGRectGetMaxX(popupRect) > CGRectGetMaxX(self.superview.bounds))
    //    popupRect.origin.x = CGRectGetMaxX(self.superview.bounds) - CGRectGetWidth(popupRect) - 1.0;

    valuePopupView.arrowOffset = CGRectGetMidX(_thumbRect) - CGRectGetMidX(popupRect);

    valuePopupView.frame = popupRect;
    valuePopupView.text = self.textValue;
    [valuePopupView setNeedsDisplay];
}

#pragma mark Memory management

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _constructSlider];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _constructSlider];
    }
    return self;
}


#pragma mark -
#pragma mark UIControl touch event tracking
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade in and update the popup view
    CGPoint touchPoint = [touch locationInView:self];
    // Check if the knob is touched. Only in this case show the popup-view
    if(CGRectContainsPoint(CGRectInset(self.thumbRect, -14.0, -12.0), touchPoint)) {
        [self _positionAndUpdatePopupView];
        [self _fadePopupViewInAndOut:YES];
    }
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Update the popup view as slider knob is being moved
    [self _positionAndUpdatePopupView];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade out the popoup view
    [self _fadePopupViewInAndOut:NO];
    [super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark -
#pragma mark Custom property accessors
-(CGRect) thumbRect {
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbR = [self thumbRectForBounds:self.bounds
                                         trackRect:trackRect
                                             value:self.value];
    return thumbR;
}

@end
