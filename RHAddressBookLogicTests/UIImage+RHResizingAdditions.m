//
//  UIImage+RHResizingAdditions.m
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

#import "UIImage+RHResizingAdditions.h"

@implementation UIImage (RHResizingAdditions)


-(UIImage *)imageResizedToSize:(CGSize)size{
    return UIImageResizeImageToSize(self, size);
}

@end



#pragma mark - underlying implementation

UIImage * UIImageResizeImageToSize(UIImage *image, CGSize size){
    
    CGImageRef imageRef = image.CGImage;    
    if (!imageRef) return nil; //unsupported
    
    CGContextRef context = CGBitmapContextCreate(NULL,  size.width,  size.height, CGImageGetBitsPerComponent(imageRef), 0, CGImageGetColorSpace(imageRef), CGImageGetBitmapInfo(imageRef));
    if (! context) {
        //likely an image in a unsupported bitmap parameter combination, try again with a standard set
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(NULL,  size.width,  size.height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
    }
    
    if (!context) return nil; //if that also fails, bail
    
    //high quality
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image.CGImage);
    
    CGImageRef resizedImageRef = CGBitmapContextCreateImage(context);
        
    //apply the same attributes to the new UIImage. (ie we resize the CGImage as is, then let the new image know if it needs to translate it for display etc.)
    UIImage *resizedImage = nil;
    if (resizedImageRef){
        resizedImage = [UIImage imageWithCGImage:resizedImageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(resizedImageRef);
    }
    
    CGContextRelease(context);
    
    return resizedImage;
}

//include an implementation in this file so we don't have to use -load_all for this category to be included in a static lib
@interface RHFixCategoryBugClassRHRA : NSObject  @end @implementation RHFixCategoryBugClassRHRA @end
