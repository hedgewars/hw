/*
 *  CGPointUtils.h
 *  PinchMe
 *
 *  Created by Jeff LaMarche on 8/2/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <CoreGraphics/CoreGraphics.h>

#define degreesToRadian(x)  (M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI)

#define HWX(x) (int)(x-screen.size.height/2)
#define HWY(x) (int)(screen.size.width-x)

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second);
CGFloat angleBetweenPoints(CGPoint first, CGPoint second);
CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint lin2End);
