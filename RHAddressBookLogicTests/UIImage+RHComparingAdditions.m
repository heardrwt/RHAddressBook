//
//  UIImage+RHComparingAdditions.m
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

#import "UIImage+RHComparingAdditions.h"

@implementation UIImage (RHComparingAdditions)


-(CGFloat)percentageDifferenceBetweenImage:(UIImage *)image{
    return UIImagePercentageDifferenceBetweenImages(self, image);
}

-(CGFloat)percentageDifferenceBetweenImage:(UIImage *)image withTolerance:(CGFloat)percentageTolerance{
    return UIImagePercentageDifferenceBetweenImagesWithTolerance(self, image, percentageTolerance, NO);
}

-(CGFloat)percentageDifferenceBetweenImage:(UIImage *)image withTolerance:(CGFloat)percentageTolerance andScaleIfImageSizesMismatched:(BOOL)shouldScale{
    return UIImagePercentageDifferenceBetweenImagesWithTolerance(self, image, percentageTolerance, shouldScale);
}

@end


#pragma mark - underlying implementation

CGFloat UIImagePercentageDifferenceBetweenImages(UIImage* image1, UIImage* image2){
    return UIImagePercentageDifferenceBetweenImagesWithTolerance(image1, image2, 0.1f, NO);
}

CGFloat UIImagePercentageDifferenceBetweenImagesWithTolerance(UIImage* image1, UIImage* image2, CGFloat percentageTolerance, BOOL shouldScaleIfImageSizesMismatched){

    //make sure we have 2 images
    if (!image1) return 1.0f;
    if (!image2) return 1.0f;
    int tolerance = MAX(0.0f, MIN(1.0f, percentageTolerance)) * 255;
    
    float width = image1.size.width;
    float height = image1.size.height;
    
    if (width != image2.size.width || height != image2.size.height){
        
        if (shouldScaleIfImageSizesMismatched){
            //scale the larger image to match the size of the smaller image
            if ((image1.size.width * image1.size.height) > (image2.size.width * image2.size.height)){
                image1 = [image1 imageResizedToSize:image2.size];
            } else {
                image2 = [image2 imageResizedToSize:image1.size];            
            }
            
            if (!image1 || !image2){
                NSLog(@"Error: Failed to scale an image for comparison.");
                return 1.0f;
            }

            //reset
            width = image1.size.width;
            height = image1.size.height;

        } else {
            return 1.0f; //maximum difference
        }
    }
        
    
    pixel *image1Pixels = UIImageCopyRGBAForImage(image1);
    pixel *image2Pixels = UIImageCopyRGBAForImage(image2);
    
    unsigned long detectedDifferences = 0;
    unsigned long totalPixelCount = width * height;
    
    //we will mutate the pointers, so make a copy
    pixel *image1Ptr = image1Pixels;
    pixel *image2Ptr = image2Pixels;
    for (unsigned long index = 0; index < totalPixelCount; index++) {
        
        
        if (abs(image1Ptr->R - image2Ptr->R) > tolerance || abs(image1Ptr->G - image2Ptr->G) > tolerance || abs(image1Ptr->B - image2Ptr->B) > tolerance || abs(image1Ptr->A - image2Ptr->A) > tolerance) {
            //one or more pixel components differs by tolerance or more
            detectedDifferences++;
        }
        
        //increment pointers
        image1Ptr++;
        image2Ptr++;
        
    }
    
    free(image1Pixels);
    free(image2Pixels);
    
    return (float)detectedDifferences / (float)totalPixelCount;

}


//include an implementation in this file so we don't have to use -load_all for this category to be included in a static lib
@interface RHFixCategoryBugClassRHCA : NSObject  @end @implementation RHFixCategoryBugClassRHCA @end
