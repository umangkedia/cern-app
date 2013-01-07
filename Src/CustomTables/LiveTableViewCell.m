//
//  LiveTableViewCell.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/7/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "LiveTableViewCell.h"

@implementation LiveTableViewCell

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewCellStyle) style reuseIdentifier : (NSString *) reuseIdentifier
{
   return self = [super initWithStyle : style reuseIdentifier : reuseIdentifier];
}

//________________________________________________________________________________________
- (void)setSelected : (BOOL)selected animated : (BOOL) animated
{
   [super setSelected : selected animated : animated];
   // Configure the view for the selected state
}

//________________________________________________________________________________________
- (void) drawRect : (CGRect) rect
{
   CGContextRef ctx = UIGraphicsGetCurrentContext();

   CGContextSetRGBFillColor(ctx, 0.415f, 0.431f, 0.49f, 1.f);//CernAPP::childMenuItemFillColor
   CGContextFillRect(ctx, rect);
   
   CGContextSetAllowsAntialiasing(ctx, false);

   //Bright line at the top.
   CGContextSetRGBStrokeColor(ctx, 0.458f, 0.478f, 0.533f, 1.f);
   CGContextMoveToPoint(ctx, 0.f, 1.f);
   CGContextAddLineToPoint(ctx, rect.size.width, 1.f);
   CGContextStrokePath(ctx);
   
   //Dark line at the bottom.
   CGContextSetRGBStrokeColor(ctx, 0.365f, 0.38f, 0.427f, 1.f);
   CGContextMoveToPoint(ctx, 0.f, rect.size.height);
   CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height);
   CGContextStrokePath(ctx);
   
   CGContextSetAllowsAntialiasing(ctx, true);
}

@end
