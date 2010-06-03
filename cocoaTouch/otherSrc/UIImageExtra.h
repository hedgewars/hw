//
//  UIImageExtra.h
//  HedgewarsMobile
//
//  Created by Vittorio on 08/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIImage (extra)
 
-(UIImage *)scaleToSize:(CGSize) size;
-(UIImage *)mergeWith:(UIImage *)secondImage atPoint:(CGPoint) secondImagePoint;
-(UIImage *)mergeWith:(UIImage *)secondImage atPoint:(CGPoint) secondImagePoint atSize:(CGSize) resultingSize;
-(id) initWithContentsOfFile:(NSString *)path andCutAt:(CGRect) rect;
-(UIImage *)convertToGrayScale;
-(UIImage *)maskImageWith:(UIImage *)maskImage;
-(UIImage *)makeRoundCornersOfSize:(CGSize) sizewh;

@end
