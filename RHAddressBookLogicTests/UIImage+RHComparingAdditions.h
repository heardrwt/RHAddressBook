//
//  UIImage+RHComparingAdditions.h
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

// Pixel level image comparison, supports various thresholds for slight variations in images (eg from colour correction etc.)
// also supports resizing one of the 2 images being compared if they are not currently the same size, so that a px by px comparison is possible.

#import <UIKit/UIKit.h>

#import "UIImage+RHPixelAdditions.h"
#import "UIImage+RHResizingAdditions.h"

@interface UIImage (RHComparingAdditions)


-(CGFloat)percentageDifferenceBetweenImage:(UIImage *)image; //use a default tolerance of 0.1f; (10% of 255 so 25 steps)
-(CGFloat)percentageDifferenceBetweenImage:(UIImage *)image withTolerance:(CGFloat)percentageTolerance; //no scale (ie mismatched images return 1.0f)
-(CGFloat)percentageDifferenceBetweenImage:(UIImage *)image withTolerance:(CGFloat)percentageTolerance andScaleIfImageSizesMismatched:(BOOL)shouldScale;

@end



#pragma mark - underlying implementation

CGFloat UIImagePercentageDifferenceBetweenImages(UIImage* image1, UIImage* image2); // default tolerance of 25 (10% of of 255)
CGFloat UIImagePercentageDifferenceBetweenImagesWithTolerance(UIImage* image1, UIImage* image2, CGFloat percentageTolerance, BOOL shouldScaleIfImageSizesMismatched);