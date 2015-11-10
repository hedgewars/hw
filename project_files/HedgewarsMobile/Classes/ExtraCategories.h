/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
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


@interface UIScreen (safe)

-(CGFloat) safeScale;
-(CGRect) safeBounds;

@end


@interface UITableView (backgroundColor)

-(void) setBackgroundColorForAnyTable:(UIColor *)color;

@end


@interface UIColor (HWColors)

+(UIColor *)darkYellowColor;
+(UIColor *)lightYellowColor;
+(UIColor *)darkBlueColor;
+(UIColor *)darkBlueColorTransparent;
+(UIColor *)blackColorTransparent;

@end


@interface UIButton (quickStyle)

-(id) initWithFrame:(CGRect) frame andTitle:(NSString *)title;

- (void)applyBlackQuickStyle;
- (void)applyDarkBlueQuickStyle;

@end


@interface UILabel (quickStyle)

-(id) initWithFrame:(CGRect)frame andTitle:(NSString *)title;
-(id) initWithFrame:(CGRect)frame andTitle:(NSString *)title withBorderWidth:(CGFloat) borderWidth;
-(id) initWithFrame:(CGRect)frame andTitle:(NSString *)title withBorderWidth:(CGFloat) borderWidth
    withBorderColor:(UIColor *)borderColor withBackgroundColor:(UIColor *)backColor;

@end


@interface NSString (MD5)

-(NSString *)MD5hash;

@end

