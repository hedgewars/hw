/*
 *  CGPointUtils.h
 *  PinchMe
 *
 *  Created by Jeff LaMarche on 8/2/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <CoreGraphics/CoreGraphics.h>

#define degreesToRadians(x) ( M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI )

// 40 is not a good value for iphone but works for ipad
#define HWX(x) (int)(x-screen.size.height/2)/HW_zoomFactor()
#define HWY(x) (int)(screen.size.width-x)/HW_zoomFactor() + 40*HW_zoomLevel()/HW_zoomFactor()

#define HWXZ(x) (int)(x-screen.size.height/2)
#define HWYZ(x) (int)(screen.size.width-x)

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second);
CGFloat angleBetweenPoints(CGPoint first, CGPoint second);
CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End);
