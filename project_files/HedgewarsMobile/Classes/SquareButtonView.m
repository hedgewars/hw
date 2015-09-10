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


#import "SquareButtonView.h"
#import <QuartzCore/QuartzCore.h>


@implementation SquareButtonView
@synthesize ownerDictionary, colorIndex, selectedColor, colorArray;

-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.colorIndex = 0;
        self.selectedColor = 0;

        self.colorArray = [HWUtils teamColors];

        // set the color to the first available one
        [self nextColor];

        // this makes the button round and nice with a border
        [self.layer setCornerRadius:7.0f];
        [self.layer setMasksToBounds:YES];
        [self.layer setBorderWidth:2];
        [self.layer setBorderColor:[[UIColor darkYellowColor] CGColor]];

        // this changes the color at button press
        [self addTarget:self action:@selector(nextColor) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void) nextColor {
    self.colorIndex++;

    if (self.colorIndex >= [self.colorArray count])
        self.colorIndex = 0;

    NSNumber *colorNumber = [self.colorArray objectAtIndex:colorIndex];
    [self.ownerDictionary setObject:colorNumber forKey:@"color"];
    NSUInteger color = [colorNumber unsignedIntValue];
    [self selectColor:color];
}

-(void) selectColor:(NSUInteger) color {
    if (color != self.selectedColor) {
        self.selectedColor = color;
        self.colorIndex = [self.colorArray indexOfObject:[NSNumber numberWithUnsignedInteger:color]];

        self.backgroundColor = [UIColor colorWithRed:((color & 0x00FF0000) >> 16)/255.0f
                                               green:((color & 0x0000FF00) >> 8)/255.0f
                                                blue: (color & 0x000000FF)/255.0f
                                               alpha:1.0f];
    }
}

-(void) dealloc {
    releaseAndNil(ownerDictionary);
    releaseAndNil(colorArray);
    [super dealloc];
}


@end
