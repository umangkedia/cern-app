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
 
   CGContextSetRGBFillColor(ctx, childMenuFillColor[0], childMenuFillColor[1], childMenuFillColor[2], 1.f);
   CGContextFillRect(ctx, rect);
   
   CernAPP::DrawFrame(ctx, rect);
}

@end
