//
//  HogButtonView.h
//  HedgewarsMobile
//
//  Created by Vittorio on 20/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HogButtonView : UIButton {
    NSInteger numberOfHogs;
    UIImage *singleHog;
    NSMutableDictionary *ownerDictionary;
}

@property (nonatomic,retain) UIImage *singleHog;
@property (nonatomic) NSInteger numberOfHogs;
@property (nonatomic,retain) NSMutableDictionary *ownerDictionary;

-(void) drawManyHogs:(NSInteger) hogs;
-(void) addOne;

@end
