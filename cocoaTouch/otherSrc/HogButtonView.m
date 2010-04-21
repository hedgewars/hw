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
@synthesize singleHog;

-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        numberOfHogs = 4;
        self.backgroundColor = [UIColor clearColor];
        
        NSString *normalHogFile = [[NSString alloc] initWithFormat:@"%@/Hedgehog.png",GRAPHICS_DIRECTORY()];
        UIImage *normalHogSprite = [[UIImage alloc] initWithContentsOfFile:normalHogFile andCutAt:CGRectMake(96, 0, 32, 32)];
        [normalHogFile release];
        
        self.singleHog = normalHogSprite;
        [normalHogSprite release];
        
        [self drawManyHogs];
    }
    return self;
}

-(void) drawManyHogs {
    UIImage *teamHogs = [[UIImage alloc] init];
    for (int i = 0; i < numberOfHogs; i++) {
        teamHogs = [singleHog mergeWith:teamHogs
                                atPoint:CGPointMake(8, 0) 
                                 atSize:CGSizeMake(88, 32)];
    }
    [self setImage:teamHogs forState:UIControlStateNormal];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
	switch ([touch tapCount]) {
		case 1:
            if (numberOfHogs < MAX_HOGS) {
                numberOfHogs++;
            } else {
                numberOfHogs = 1;
            }
			break;
		case 2:
            if (numberOfHogs > 2) {
                numberOfHogs--;
                numberOfHogs--;
            } else {
                numberOfHogs = MAX_HOGS;
            }
            break;
		default:
			break;
	}
    NSLog(@"numberOfHogs: %d", numberOfHogs);
    [self drawManyHogs];
}

-(void) dealloc {
    [singleHog release];
    [super dealloc];
}


@end
