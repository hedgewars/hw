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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#include "CGPointUtils.h"
#include "math.h"


CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
}

CGFloat angleBetweenPoints(CGPoint first, CGPoint second) {
    CGFloat height = second.y - first.y;
    CGFloat width = first.x - second.x;
    CGFloat rads = atan(height/width);
    return radiansToDegrees(rads);
}

CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End) {
    CGFloat a = line1End.x - line1Start.x;
    CGFloat b = line1End.y - line1Start.y;
    CGFloat c = line2End.x - line2Start.x;
    CGFloat d = line2End.y - line2Start.y;
    CGFloat rads = acos(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    return radiansToDegrees(rads);
}

CGFloat CGPointDot(CGPoint a,CGPoint b) {
    return a.x*b.x+a.y*b.y;
}

CGFloat CGPointLen(CGPoint a) {
    return sqrtf(a.x*a.x+a.y*a.y);
}

CGPoint CGPointSub(CGPoint a,CGPoint b) {
    CGPoint c = {a.x-b.x,a.y-b.y};
    return c;
}

CGFloat CGPointDist(CGPoint a,CGPoint b) {
    CGPoint c = CGPointSub(a,b);
    return CGPointLen(c);
}

CGPoint CGPointNorm(CGPoint a) {
    CGFloat m = sqrtf(a.x*a.x+a.y*a.y);
    CGPoint c;
    c.x = a.x/m;
    c.y = a.y/m;
    return c;
}
