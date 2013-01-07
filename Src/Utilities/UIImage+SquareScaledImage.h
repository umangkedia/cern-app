//
//  UIImage+SquareScaledImage.h
//  CERN App
//
//  Created by Eamon Ford on 7/28/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (SquareScaledImage)

+ (UIImage *)squareImageWithDimension:(float)dimension fromImage:(UIImage *)originalImage;

@end
