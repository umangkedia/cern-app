//
//  BulletinViewCell.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/17/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "BulletinViewCell.h"
#import "GUIHelpers.h"

@implementation BackgroundView

@synthesize selectedView;

//________________________________________________________________________________________
- (void) drawRect : (CGRect) rect
{
   // draw a rounded rect bezier path filled with blue
   
   CGContextRef ctx = UIGraphicsGetCurrentContext();
   CGContextSaveGState(ctx);

   CGContextSetRGBFillColor(ctx, 1.f, 1.f, 1.f, 1.f);
   CGContextFillRect(ctx, rect);
   
   //Draw a gray line.
   CGContextSetAllowsAntialiasing(ctx, false);
   
   CGContextSetRGBStrokeColor(ctx, 224 / 255.f, 224 / 255.f, 224 / 255.f, 1.f);
   CGContextMoveToPoint(ctx, 0.f, rect.size.height);
   CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height);
   CGContextStrokePath(ctx);

   CGContextSetAllowsAntialiasing(ctx, true);
}

@end
