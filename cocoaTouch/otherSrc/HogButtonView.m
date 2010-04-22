//
//  HogButtonView.m
//  HedgewarsMobile
//
//  Created by Vittorio on 20/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HogButtonView.h"
#import "CommodityFunctions.h"
#import "UIImageExtra.h"

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
    self.highlighted = NO;
    NSInteger number = self.numberOfHogs;
    number++;
    [self drawManyHogs:number];
}

-(void) drawManyHogs:(NSInteger) hogs {
    if (numberOfHogs != hogs) {
        if (hogs <= MAX_HOGS && hogs >= 1)
            numberOfHogs = hogs;
        else {
            if (hogs > MAX_HOGS)
                numberOfHogs = 1;
            else
                numberOfHogs = MAX_HOGS;
        }
        [ownerDictionary setObject:[NSNumber numberWithInt:numberOfHogs] forKey:@"number"];
        
        UIImage *teamHogs = [[[UIImage alloc] init] autorelease];
        for (int i = 0; i < numberOfHogs; i++) {
            teamHogs = [singleHog mergeWith:teamHogs
                                    atPoint:CGPointMake(8, 0) 
                                     atSize:CGSizeMake(88, 32)];
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
