//
//  UIImage+RHPixelAdditions.m
//  RHKit
//
//  Created by Richard Heard on 18/03/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "UIImage+RHPixelAdditions.h"

@implementation UIImage (RHPixelAdditions)

-(NSData *)rgba{
    return UIImageGetRGBAForImage(self);
}
-(NSData *)rgbaForPoint:(CGPoint)point{
    return UIImageGetRGBAForPointInImage(point, self);
}

@end


#pragma mark - underlying implementation

pixel * UIImageCopyRGBAForImage(UIImage *image){
    
    if (!image) return NULL;

    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    
    pixel *pixels = calloc(width * height, sizeof(pixel));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

    if (context) {
        UIGraphicsPushContext(context);
        [image drawAtPoint:CGPointMake(0,0)];
        UIGraphicsPopContext();
    }
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return pixels;
}

pixel * UIImageCopyRGBAForPointInImage(CGPoint point, UIImage*image){
    
    if (!image) return NULL;
    
    CGFloat width = 1.0f;
    CGFloat height = 1.0f;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    
    pixel *pixels = calloc(width * height, sizeof(pixel));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

    if (context){
        UIGraphicsPushContext(context);
        [image drawAtPoint:CGPointMake(-point.x, -point.y)];
        UIGraphicsPopContext();
    }
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return pixels;
}


NSData * UIImageGetRGBAForImage(UIImage* image){
    pixel *pixels = UIImageCopyRGBAForImage(image);
    if (!pixels) return nil;

    NSData *data = [NSData dataWithBytes:pixels length:(4 * image.size.width * image.size.height)]; 
    free(pixels);
    
    return data;
}

NSData * UIImageGetRGBAForPointInImage(CGPoint point, UIImage* image){
    pixel *pixels = UIImageCopyRGBAForPointInImage(point, image);
    if (!pixels) return nil;
    
    NSData *data = [NSData dataWithBytes:pixels length:(4 * 1 * 1)]; 
    free(pixels);
    
    return data;
}

//include an implementation in this file so we don't have to use -load_all for this category to be included in a static lib
@interface RHFixCategoryBugClassRHPA : NSObject  @end @implementation RHFixCategoryBugClassRHPA @end
