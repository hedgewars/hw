/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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


#import <Foundation/Foundation.h>


@interface UIImage (extra)

+ (UIImage *)whiteImage:(CGSize)ofSize;
+ (UIImage *)drawHogsRepeated:(NSInteger)manyTimes;
+ (CGSize)imageSizeFromMetadataOf:(NSString *)aFileName;

- (UIImage *)scaleToSize:(CGSize)size;
- (UIImage *)mergeWith:(UIImage *)secondImage atPoint:(CGPoint)secondImagePoint;
- (id)initWithContentsOfFile:(NSString *)path andCutAt:(CGRect)rect;
- (UIImage *)cutAt:(CGRect)rect;
- (UIImage *)convertToGrayScale;
- (UIImage *)convertToNegative;
- (UIImage *)maskImageWith:(UIImage *)maskImage;
- (UIImage *)makeRoundCornersOfSize:(CGSize)sizewh;

@end
