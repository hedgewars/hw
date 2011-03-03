/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 03/10/2010.
 */


#import <CoreGraphics/CoreGraphics.h>

#define degreesToRadians(x) ( M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI )

#define HWX(x) (int)(x-screen.size.height/2)/HW_zoomFactor()
#define HWY(x) (int)(screen.size.width-x)/HW_zoomFactor() + (IS_IPAD()?40:17.5)*HW_zoomLevel()/HW_zoomFactor()

#define HWXZ(x) (int)(x-screen.size.height/2)
#define HWYZ(x) (int)(screen.size.width-x)

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second);
CGFloat angleBetweenPoints(CGPoint first, CGPoint second);
CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End);

CGFloat CGPointDot(CGPoint a, CGPoint b);
CGFloat CGPointLen(CGPoint a);
CGPoint CGPointSub(CGPoint a, CGPoint b);
CGFloat CGPointDist(CGPoint a, CGPoint b);
CGPoint CGPointNorm(CGPoint a);
