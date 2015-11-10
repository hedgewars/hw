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


#import "UIImageExtra.h"


@implementation UIImage (extra)

-(UIImage *)scaleToSize:(CGSize) size {
    // Create a bitmap graphics context; this will also set it as the current context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 4 * size.width, colorSpace, kCGImageAlphaPremultipliedFirst);

    // draw the image inside the context
    CGFloat screenScale = [[UIScreen mainScreen] safeScale];
    CGContextDrawImage(context, CGRectMake(0, 0, size.width*screenScale, size.height*screenScale), self.CGImage);

    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    // Create a new UIImage object
    UIImage *resultImage;
    if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
        resultImage = [UIImage imageWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];
    else
        resultImage = [UIImage imageWithCGImage:imageRef];

    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);

    return resultImage;
}

-(UIImage *)mergeWith:(UIImage *)secondImage atPoint:(CGPoint) secondImagePoint {
    if (secondImage == nil) {
        DLog(@"Warning, secondImage == nil");
        return self;
    }
    CGFloat screenScale = [[UIScreen mainScreen] safeScale];
    int w = self.size.width * screenScale;
    int h = self.size.height * screenScale;
    int yOffset = self.size.height - secondImage.size.height + secondImagePoint.y;

    if (w == 0 || h == 0) {
        DLog(@"Cannot have 0 dimesions");
        return self;
    }

    // Create a bitmap graphics context; this will also set it as the current context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h+yOffset, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);

    // draw the two images in the current context
    CGContextDrawImage(context, CGRectMake(0, 0, self.size.width*screenScale, self.size.height*screenScale), [self CGImage]);
    CGContextDrawImage(context, CGRectMake(secondImagePoint.x*screenScale, secondImagePoint.y*screenScale, secondImage.size.width*screenScale, secondImage.size.height*screenScale), [secondImage CGImage]);

    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    // Create a new UIImage object
    UIImage *resultImage;
    if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
        resultImage = [UIImage imageWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];
    else
        resultImage = [UIImage imageWithCGImage:imageRef];

    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);

    return resultImage;
}

-(id) initWithContentsOfFile:(NSString *)path andCutAt:(CGRect) rect {
    // load image from path
    UIImage *image = [[UIImage alloc] initWithContentsOfFile: path];

    if (nil != image) {
        // get its CGImage representation with a give size
        CGImageRef cgImage = CGImageCreateWithImageInRect([image CGImage], rect);

        // clean memory
        [image release];

        // create a UIImage from the CGImage (memory must be allocated already)
        UIImage *sprite = [self initWithCGImage:cgImage];

        // clean memory
        CGImageRelease(cgImage);

        // return resulting image
        return sprite;
    } else {
        DLog(@"error - image == nil");
        return nil;
    }
}

-(UIImage *)cutAt:(CGRect) rect {
    CGImageRef cgImage = CGImageCreateWithImageInRect([self CGImage], rect);

    UIImage *res = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    return res;
}

-(UIImage *)convertToGrayScale {
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);

    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, self.size.width, self.size.height, 8, 0, colorSpace, kCGImageAlphaNone);

    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [self CGImage]);

    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];

    // Release colorspace, context and bitmap information
    CFRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // Return the new grayscale image
    return newImage;
}

// by http://iphonedevelopertips.com/cocoa/how-to-mask-an-image.html turned into a category by koda
-(UIImage*) maskImageWith:(UIImage *)maskImage {
    // prepare the reference image
    CGImageRef maskRef = [maskImage CGImage];

    // create the mask using parameters of the mask reference
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);

    // create an image in the current context
    CGImageRef masked = CGImageCreateWithMask([self CGImage], mask);
    CGImageRelease(mask);

    UIImage* retImage = [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);

    return retImage;
}

// by http://blog.sallarp.com/iphone-uiimage-round-corners/ turned into a category by koda
void addRoundedRectToPath(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight) {
    CGFloat fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

-(UIImage *)makeRoundCornersOfSize:(CGSize) sizewh {
    CGFloat cornerWidth = sizewh.width;
    CGFloat cornerHeight = sizewh.height;
    CGFloat screenScale = [[UIScreen mainScreen] safeScale];
    CGFloat w = self.size.width * screenScale;
    CGFloat h = self.size.height * screenScale;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);

    CGContextBeginPath(context);
    CGRect rect = CGRectMake(0, 0, w, h);
    addRoundedRectToPath(context, rect, cornerWidth, cornerHeight);
    CGContextClosePath(context);
    CGContextClip(context);

    CGContextDrawImage(context, CGRectMake(0, 0, w, h), [self CGImage]);

    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    UIImage *resultImage;
    if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
        resultImage = [UIImage imageWithCGImage:imageMasked scale:screenScale orientation:UIImageOrientationUp];
    else
        resultImage = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);

    return resultImage;
}

// by http://www.sixtemia.com/journal/2010/06/23/uiimage-negative-color-effect/
-(UIImage *)convertToNegative {
    UIGraphicsBeginImageContext(self.size);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, self.size.width, self.size.height));
    // create an image from the current contex (not thread safe)
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+(UIImage *)whiteImage:(CGSize) ofSize {
    CGFloat w = ofSize.width;
    CGFloat h = ofSize.height;
    DLog(@"w: %f, h: %f", w, h);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);

    CGContextBeginPath(context);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context,CGRectMake(0,0,ofSize.width,ofSize.height));

    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    UIImage *bkgImg = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    return bkgImg;
}

+(UIImage *)drawHogsRepeated:(NSInteger) manyTimes {
    NSString *imgString = [[NSString alloc] initWithFormat:@"%@/hedgehog.png",[[NSBundle mainBundle] resourcePath]];
    UIImage *hogSprite = [[UIImage alloc] initWithContentsOfFile:imgString];
    [imgString release];
    CGFloat screenScale = [[UIScreen mainScreen] safeScale];
    int w = hogSprite.size.width * screenScale;
    int h = hogSprite.size.height * screenScale;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w * 3, h, 8, 4 * w * 3, colorSpace, kCGImageAlphaPremultipliedFirst);

    // draw the two images in the current context
    for (int i = 0; i < manyTimes; i++)
        CGContextDrawImage(context, CGRectMake(i*8*screenScale, 0, w, h), [hogSprite CGImage]);
    [hogSprite release];

    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    // Create a new UIImage object
    UIImage *resultImage;
    if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
        resultImage = [UIImage imageWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];
    else
        resultImage = [UIImage imageWithCGImage:imageRef];

    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);

    return resultImage;
}

// this routine checks for the PNG size without loading it in memory
// https://github.com/steipete/PSFramework/blob/master/PSFramework%20Version%200.3/PhotoshopFramework/PSMetaDataFunctions.m
+(CGSize) imageSizeFromMetadataOf:(NSString *)aFileName {
    // File Name to C String.
    const char *fileName = [aFileName UTF8String];
    // source file
    FILE *infile = fopen(fileName, "rb");
    if (infile == NULL) {
        DLog(@"Can't open the file: %@", aFileName);
        return CGSizeZero;
    }

    // Bytes Buffer.
    unsigned char buffer[30];
    // Grab Only First Bytes.
    fread(buffer, 1, 30, infile);
    // Close File.
    fclose(infile);

    // PNG Signature.
    unsigned char png_signature[8] = {137, 80, 78, 71, 13, 10, 26, 10};

    // Compare File signature.
    if ((int)(memcmp(&buffer[0], &png_signature[0], 8))) {
        DLog(@"The file (%@) is not a PNG file", aFileName);
        return CGSizeZero;
    }

    // Calc Sizes. Isolate only four bytes of each size (width, height).
    int width[4];
    int height[4];
    for (int d = 16; d < (16 + 4); d++) {
        width[d-16] = buffer[d];
        height[d-16] = buffer[d+4];
    }

    // Convert bytes to Long (Integer)
    long resultWidth = (width[0] << (int)24) | (width[1] << (int)16) | (width[2] << (int)8) | width[3];
    long resultHeight = (height[0] << (int)24) | (height[1] << (int)16) | (height[2] << (int)8) | height[3];

    // Return Size.
    return CGSizeMake(resultWidth,resultHeight);
}

@end
