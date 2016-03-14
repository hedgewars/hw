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


#import "ExtraCategories.h"
#import <QuartzCore/QuartzCore.h>
#import <CommonCrypto/CommonDigest.h>


#pragma mark -
@implementation UIScreen (safe)

-(CGFloat) safeScale {
    CGFloat theScale = 1.0f;
//    if ([self respondsToSelector:@selector(scale)])
//         theScale = [self scale];
    return theScale;
}

-(CGRect) safeBounds {
    return [self bounds];
//    CGRect original = [self bounds];
//    if (IS_ON_PORTRAIT())
//        return original;
//    else
//        return CGRectMake(original.origin.x, original.origin.y, original.size.height, original.size.width);
}

@end


#pragma mark -
@implementation UITableView (backgroundColor)

-(void) setBackgroundColorForAnyTable:(UIColor *) color {
    if ([self respondsToSelector:@selector(backgroundView)]) {
        UIView *backView = [[UIView alloc] initWithFrame:self.frame];
        backView.backgroundColor = color;
        self.backgroundView = backView;
        [backView release];
        self.backgroundColor = [UIColor clearColor];
    } else
        self.backgroundColor = color;
}

@end


#pragma mark -
@implementation UIColor (HWColors)

+(UIColor *)darkYellowColor {
    return [UIColor colorWithRed:(CGFloat)0xFE/255 green:(CGFloat)0xC0/255 blue:0 alpha:1];
}

+(UIColor *)lightYellowColor {
    return [UIColor colorWithRed:(CGFloat)0xF0/255 green:(CGFloat)0xD0/255 blue:0 alpha:1];
}

+(UIColor *)darkBlueColor {
    return [UIColor colorWithRed:(CGFloat)0x0F/255 green:0 blue:(CGFloat)0x42/255 alpha:1];
}

// older devices don't get any transparency for performance reasons
+(UIColor *)darkBlueColorTransparent {
    return [UIColor colorWithRed:(CGFloat)0x0F/255
                           green:0
                            blue:(CGFloat)0x55/255
                           alpha:IS_NOT_POWERFUL([HWUtils modelType]) ? 1 : 0.6f];
}

+(UIColor *)blackColorTransparent {
    return [UIColor colorWithRed:0
                           green:0
                            blue:0
                           alpha:IS_NOT_POWERFUL([HWUtils modelType]) ? 1 : 0.65f];
}

@end


#pragma mark -
@implementation UIButton (quickStyle)

-(id) initWithFrame:(CGRect) frame andTitle:(NSString *)title {
    [self initWithFrame:frame];
    [self setTitle:title forState:UIControlStateNormal];
    [self applyBlackQuickStyle];

    return self;
}

- (void)applyBlackQuickStyle
{
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    self.backgroundColor = [UIColor blackColorTransparent];
    
    [self.layer setBorderWidth:1.0f];
    [self.layer setBorderColor:[[UIColor darkYellowColor] CGColor]];
    [self.layer setCornerRadius:9.0f];
    [self.layer setMasksToBounds:YES];
}

- (void)applyDarkBlueQuickStyle
{
    [self setTitleColor:[UIColor darkYellowColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    self.backgroundColor = [UIColor darkBlueColorTransparent];
    
    [self.layer setBorderWidth:2.0f];
    [self.layer setBorderColor:[[UIColor darkYellowColor] CGColor]];
    [self.layer setCornerRadius:9.0f];
    [self.layer setMasksToBounds:YES];
}

@end


#pragma mark -
@implementation UILabel (quickStyle)

-(id) initWithFrame:(CGRect)frame andTitle:(NSString *)title {
    return [self initWithFrame:frame
                      andTitle:title
               withBorderWidth:1.5f
               withBorderColor:[UIColor darkYellowColor]
           withBackgroundColor:[UIColor darkBlueColor]];
}

-(id) initWithFrame:(CGRect)frame andTitle:(NSString *)title withBorderWidth:(CGFloat) borderWidth {
    return [self initWithFrame:frame
                      andTitle:title
               withBorderWidth:borderWidth
               withBorderColor:[UIColor darkYellowColor]
           withBackgroundColor:[UIColor darkBlueColorTransparent]];
}

-(id) initWithFrame:(CGRect)frame andTitle:(NSString *)title withBorderWidth:(CGFloat) borderWidth
          withBorderColor:(UIColor *)borderColor withBackgroundColor:(UIColor *)backColor {
    UILabel *theLabel = [self initWithFrame:frame];
    theLabel.backgroundColor = backColor;

    if (title != nil) {
        theLabel.text = title;
        theLabel.textColor = [UIColor lightYellowColor];
        theLabel.textAlignment = NSTextAlignmentCenter;
        theLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]*80/100];
    }

    [theLabel.layer setBorderWidth:borderWidth];
    [theLabel.layer setBorderColor:borderColor.CGColor];
    [theLabel.layer setCornerRadius:8.0f];
    [theLabel.layer setMasksToBounds:YES];

    return theLabel;
}

@end


#pragma mark -
@implementation NSString (MD5)

-(NSString *)MD5hash {
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5],
            result[6], result[7], result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

@end
