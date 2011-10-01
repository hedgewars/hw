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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 01/10/2011.
 */


#import "HWUtils.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <QuartzCore/QuartzCore.h>
#import <CommonCrypto/CommonDigest.h>
#import "PascalImports.h"
#import "hwconsts.h"

@implementation HWUtils

+(NSString *)modelType {
    size_t size;
    // set 'oldp' parameter to NULL to get the size of the data returned so we can allocate appropriate amount of space
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = (char *)malloc(sizeof(char) * size);
    // get the platform name
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *modelId = [NSString stringWithUTF8String:name];
    free(name);

    return modelId;
}

+(NSArray *)teamColors {
    // by default colors are ARGB but we do computation over RGB, hence we have to "& 0x00FFFFFF" before processing
    unsigned int colors[] = HW_TEAMCOLOR_ARRAY;
    NSMutableArray *array = [[NSMutableArray alloc] init];

    int i = 0;
    while(colors[i] != 0)
        [array addObject:[NSNumber numberWithUnsignedInt:(colors[i++] & 0x00FFFFFF)]];

    NSArray *final = [NSArray arrayWithArray:array];
    [array release];
    return final;
}

@end


@implementation UIColor (extra)

+(UIColor *)darkYellowColor {
    return [UIColor colorWithRed:(CGFloat)0xFE/255 green:(CGFloat)0xC0/255 blue:0 alpha:1];
}

+(UIColor *)lightYellowColor {
    return [UIColor colorWithRed:(CGFloat)0xF0/255 green:(CGFloat)0xD0/255 blue:0 alpha:1];
}

+(UIColor *)darkBlueColor {
    return [UIColor colorWithRed:(CGFloat)0x0F/255 green:0 blue:(CGFloat)0x42/255 alpha:1];
}

+(UIColor *)darkBlueColorTransparent {
    return [UIColor colorWithRed:(CGFloat)0x0F/255 green:0 blue:(CGFloat)0x42/255 alpha:0.58f];
}

+(UIColor *)blackColorTransparent {
    if (IS_NOT_POWERFUL([HWUtils modelType]))
        return [UIColor blackColor];
    else
        return [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
}

@end


@implementation UILabel (extra)

-(UILabel *)initWithFrame:(CGRect)frame andTitle:(NSString *)title {
    return [self initWithFrame:frame
                      andTitle:title
               withBorderWidth:1.5f
               withBorderColor:[UIColor darkYellowColor]
           withBackgroundColor:[UIColor darkBlueColor]];
}

-(UILabel *)initWithFrame:(CGRect)frame andTitle:(NSString *)title  withBorderWidth:(CGFloat) borderWidth {
    return [self initWithFrame:frame
                      andTitle:title
               withBorderWidth:borderWidth
               withBorderColor:[UIColor darkYellowColor]
           withBackgroundColor:[UIColor darkBlueColor]];
}

-(UILabel *)initWithFrame:(CGRect)frame andTitle:(NSString *)title  withBorderWidth:(CGFloat) borderWidth
          withBorderColor:(UIColor *)borderColor withBackgroundColor:(UIColor *)backColor{
    UILabel *theLabel = [self initWithFrame:frame];
    theLabel.backgroundColor = backColor;

    if (title != nil) {
        theLabel.text = title;
        theLabel.textColor = [UIColor lightYellowColor];
        theLabel.textAlignment = UITextAlignmentCenter;
        theLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]*80/100];
    }

    [theLabel.layer setBorderWidth:borderWidth];
    [theLabel.layer setBorderColor:borderColor.CGColor];
    [theLabel.layer setCornerRadius:8.0f];
    [theLabel.layer setMasksToBounds:YES];

    return theLabel;
}

@end


@implementation NSString (extra)

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
