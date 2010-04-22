//
//  HogButtonView.h
//  HedgewarsMobile
//
//  Created by Vittorio on 20/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SquareButtonView : UIButton {
    NSInteger colorIndex;
    NSUInteger selectedColor;
    NSArray *colorArray;
    NSMutableDictionary *ownerDictionary;
}

@property (nonatomic,retain) NSArray *colorArray;
@property (nonatomic) NSUInteger selectedColor;
@property (nonatomic,retain) NSMutableDictionary *ownerDictionary;

-(void) nextColor;
-(void) selectColor:(NSUInteger) color;

@end
