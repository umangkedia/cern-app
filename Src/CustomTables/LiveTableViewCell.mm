//
//  LiveTableViewCell.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/7/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "LiveTableViewCell.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"

namespace CernAPP {

const CGFloat liveTableRgbShift = 0.15f;

}

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

   using CernAPP::childMenuFillColor;
   using CernAPP::liveTableRgbShift;
 
   CGContextSetRGBFillColor(ctx, childMenuFillColor[0] + liveTableRgbShift, childMenuFillColor[1] + liveTableRgbShift, childMenuFillColor[2] + liveTableRgbShift, 1.f);
   CGContextFillRect(ctx, rect);
   
   CernAPP::DrawFrame(ctx, rect, liveTableRgbShift);
}

@end
