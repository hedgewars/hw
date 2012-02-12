//
// MNEValueTrackingSlider
//
// Copyright 2011 Michael Neuwert
// "You can use the code in your own project and modify it as you like."
// http://blog.neuwert-media.com/2011/04/customized-uislider-with-visual-value-tracking/
//


#import <Foundation/Foundation.h>

@class SliderValuePopupView;

@interface MNEValueTrackingSlider : UISlider {
    SliderValuePopupView *valuePopupView;
    NSString *textValue;
}

@property (nonatomic, readonly) CGRect thumbRect;
@property (nonatomic, retain) NSString *textValue;

@end
