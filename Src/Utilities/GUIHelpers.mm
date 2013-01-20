//
//  GUIHelpers.m
//  ECSlidingViewController
//
//  Created by Timur Pocheptsov on 1/1/13.
//
//

#import <cassert>

#import "GUIHelpers.h"

namespace CernAPP {

const CGFloat spinnerSize = 150.f;
const CGSize navBarBackButtonSize  = CGSizeMake(35.f, 35.f);
const CGFloat navBarHeight = 44.f;
const CGFloat separatorItemHeight = 20.f;

//Menu.
const CGFloat groupMenuItemHeight = 44.f;
const CGFloat childMenuItemHeight = 30.f;
const CGFloat childMenuItemTextIndent = 20.f;
NSString * const childMenuFontName = @"PTSans-Caption";
NSString * const groupMenuFontName = @"PTSans-Bold";
const CGFloat groupMenuItemImageHeight = 24.f;
const CGFloat childMenuItemImageHeight = 15.f;
const CGFloat childTextColor[] = {0.772f, 0.796f, 0.847f};
const CGFloat childMenuFillColor[] = {0.215f, 0.231f, 0.29f};
const CGFloat menuBackgroundColor[4] = {0.242f, 0.258f, 0.321f, 1.f};
const CGFloat menuItemHighlightColor[2][4] = {{0.f, 0.564f, 0.949f, 1.f}, {0.f, 0.431f, .901, 1.f}};

//________________________________________________________________________________________
void GradientFillRect(CGContextRef ctx, const CGRect &rect, const CGFloat *gradientColor)
{
   //Simple gradient, two colors only.

   assert(ctx != nullptr && "GradientFillRect, parameter 'ctx' is null");
   assert(gradientColor != nullptr && "GradientFillRect, parameter 'gradientColor' is null");
   
   const CGPoint startPoint = CGPointZero;
   const CGPoint endPoint = CGPointMake(0.f, rect.size.height);
      
   //Create a gradient.
   CGColorSpaceRef baseSpace(CGColorSpaceCreateDeviceRGB());
   const CGFloat positions[] = {0.f, 1.f};//Always fixed.

   CGGradientRef gradient(CGGradientCreateWithColorComponents(baseSpace, gradientColor, positions, 2));//fixed, 2 colors only.
   CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
      
   CGGradientRelease(gradient);
   CGColorSpaceRelease(baseSpace);
}

}
