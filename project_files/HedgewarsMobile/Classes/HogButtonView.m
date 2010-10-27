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
 * File created on 20/04/2010.
 */


#import "HogButtonView.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"
#import "PascalImports.h"

@implementation HogButtonView
@synthesize singleHog, numberOfHogs, ownerDictionary;

-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];

        NSString *normalHogFile = [[NSString alloc] initWithFormat:@"%@/Hedgehog.png",GRAPHICS_DIRECTORY()];
        UIImage *normalHogSprite = [[UIImage alloc] initWithContentsOfFile:normalHogFile andCutAt:CGRectMake(96, 0, 32, 32)];
        [normalHogFile release];

        self.singleHog = normalHogSprite;
        [normalHogSprite release];
        [self addTarget:self action:@selector(addOne) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void) addOne {
    playSound(@"clickSound");
    self.highlighted = NO;
    NSInteger number = self.numberOfHogs;
    number++;
    [self drawManyHogs:number];
}

-(void) drawManyHogs:(NSInteger) hogs {
    if (numberOfHogs != hogs) {
        if (hogs <= HW_getMaxNumberOfHogs() && hogs >= 1)
            numberOfHogs = hogs;
        else {
            if (hogs > HW_getMaxNumberOfHogs())
                numberOfHogs = 1;
            else
                numberOfHogs = HW_getMaxNumberOfHogs();
        }
        [ownerDictionary setObject:[NSNumber numberWithInt:numberOfHogs] forKey:@"number"];

        UIImage *teamHogs = [[[UIImage alloc] init] autorelease];
        for (int i = 0; i < numberOfHogs; i++) {
            teamHogs = [singleHog mergeWith:teamHogs
                                    atPoint:CGPointMake(8, 0)
                                     ofSize:CGSizeMake(88, 32)];
        }
        [self setImage:teamHogs forState:UIControlStateNormal];
    }
}

-(void) dealloc {
    [ownerDictionary release];
    [singleHog release];
    [super dealloc];
}


@end
