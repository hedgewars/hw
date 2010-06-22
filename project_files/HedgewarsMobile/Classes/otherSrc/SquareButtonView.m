//
//  HogButtonView.m
//  HedgewarsMobile
//
//  Created by Vittorio on 20/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SquareButtonView.h"
#import <QuartzCore/QuartzCore.h>
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

@implementation SquareButtonView
@synthesize colorArray, selectedColor, ownerDictionary;

-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        colorIndex = -1;
        selectedColor = 0;

        // list of allowed colors
        NSArray *colors = [[NSArray alloc] initWithObjects: [NSNumber numberWithUnsignedInt:4421353],    // bluette
                                                            [NSNumber numberWithUnsignedInt:4100897],    // greeeen
                                                            [NSNumber numberWithUnsignedInt:10632635],   // violett
                                                            [NSNumber numberWithUnsignedInt:16749353],   // oranngy
                                                            [NSNumber numberWithUnsignedInt:14483456],   // reddish
                                                            [NSNumber numberWithUnsignedInt:7566195],    // graaaay
                                                            nil];
        self.colorArray = colors;
        [colors release];

        // set the color to the first available one
        [self nextColor];
        
        // this makes the button round and nice with a border
        [self.layer setCornerRadius:7.0f];
        [self.layer setMasksToBounds:YES];        
        [self.layer setBorderWidth:2];
        
        // this changes the color at button press
        [self addTarget:self action:@selector(nextColor) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void) nextColor {
    colorIndex++;

    if (colorIndex >= [colorArray count])
        colorIndex = 0;

    NSUInteger color = [[self.colorArray objectAtIndex:colorIndex] unsignedIntValue];
    self.backgroundColor = [UIColor colorWithRed:((color & 0x00FF0000) >> 16)/255.0f 
                                           green:((color & 0x0000FF00) >> 8)/255.0f 
                                            blue: (color & 0x000000FF)/255.0f 
                                           alpha:1.0f];
    
    [ownerDictionary setObject:[NSNumber numberWithInt:color] forKey:@"color"];
}

-(void) selectColor:(NSUInteger) color {
    if (color != selectedColor) {
        selectedColor = color;
        colorIndex = [colorArray indexOfObject:[NSNumber numberWithUnsignedInt:color]];
        
        self.backgroundColor = [UIColor colorWithRed:((color & 0x00FF0000) >> 16)/255.0f 
                                               green:((color & 0x0000FF00) >> 8)/255.0f 
                                                blue: (color & 0x000000FF)/255.0f 
                                               alpha:1.0f];
    }
}

-(void) dealloc {
    [ownerDictionary release];
    [colorArray release];
    [super dealloc];
}


@end
