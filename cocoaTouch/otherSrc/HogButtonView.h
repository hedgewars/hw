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
}

@property (nonatomic,retain) UIImage *singleHog;

-(void) drawManyHogs;

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end
