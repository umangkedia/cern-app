//
//  LiveTableViewCell.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/7/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "MenuItemViews.h"
#import "MenuViewCell.h"
#import "GUIHelpers.h"

namespace CernAPP {

const CGFloat menuTableRgbShift = 0.15f;

}

@implementation MenuViewCell

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

   using CernAPP::childMenuFillColor;
   using CernAPP::menuTableRgbShift;
 
   CGContextSetRGBFillColor(ctx, childMenuFillColor[0] + menuTableRgbShift, childMenuFillColor[1] + menuTableRgbShift, childMenuFillColor[2] + menuTableRgbShift, 1.f);
   CGContextFillRect(ctx, rect);
   
   CernAPP::DrawFrame(ctx, rect, menuTableRgbShift);
}

@end
