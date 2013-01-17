//
//  BulletinViewCell.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/17/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "BulletinViewCell.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"

@implementation BulletinViewCell

@synthesize cellLabel;

//________________________________________________________________________________________
- (id)initWithStyle : (UITableViewCellStyle) style reuseIdentifier : (NSString *) reuseIdentifier
{
   if (self = [super initWithStyle : style reuseIdentifier : reuseIdentifier])
      cellLabel = [[UILabel alloc] initWithFrame : CGRect()];

   return self;
}

@end

@implementation BackgroundView

@synthesize selectedView;

//________________________________________________________________________________________
- (void) drawRect : (CGRect) rect
{
   // draw a rounded rect bezier path filled with blue
   
   CGContextRef ctx = UIGraphicsGetCurrentContext();
   CGContextSaveGState(ctx);
   
//   rect.origin.y += 5.;
//   rect.size.height -= 10.;
   
   UIBezierPath * const bezierPath = [UIBezierPath bezierPathWithRoundedRect : rect cornerRadius : 10.f];

   CGContextBeginPath(ctx);
   CGContextAddPath(ctx, bezierPath.CGPath);
   CGContextClosePath(ctx);
   CGContextClip(ctx);
   //
   if (selectedView)
      CernAPP::GradientFillRect(ctx, rect, CernAPP::menuItemHighlightColor[0]);
   else {
      CGContextSetRGBFillColor(ctx, 1.f, 1.f, 1.f, 1.f);
      CGContextFillRect(ctx, rect);
   }

   //
   CGContextRestoreGState(ctx);
}

@end
