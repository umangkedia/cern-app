//
//  MenuItemViews.m
//  slide_menu
//
//  Created by Timur Pocheptsov on 1/7/13.
//  Copyright (c) 2013 Timur Pocheptsov. All rights reserved.
//

#import <cassert>

#import <QuartzCore/QuartzCore.h>

#import "MenuViewController.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"

//Menu GUI constants.
//It's a C++, all these constants have
//internal linkage without any 'static',
//and no need for unnamed namespace.
const CGFloat groupMenuItemFontSize = 17.f;
const CGFloat childMenuItemFontSize = 13.f;
NSString * const groupMenuFontName = @"PTSans-Bold";
const CGSize menuTextShadowOffset = CGSizeMake(2.f, 2.f);
const CGFloat menuTextShadowAlpha = 0.5f;
const CGFloat menuItemImageSize = 24.f;//must be square image.
const CGFloat groupMenuItemTextIndent = 10.f;
const CGFloat groupMenuItemTextHeight = 20.f;
const CGFloat childMenuItemTextHeight = 20.f;
const CGFloat discloseTriangleSize = 14.f;
const CGFloat groupMenuItemLeftMargin = 80.f;
const CGFloat childMenuItemImageSize = 15.f;

const CGFloat groupMenuFillColor[][4] = {{0.247f, 0.29f, 0.36f, 1.f}, {0.242f, 0.258f, 0.321f, 1.f}};
const CGFloat frameTopLineColor[] = {0.258f, 0.278f, 0.33f};
const CGFloat frameBottomLineColor[] = {0.165f, 0.18f, 0.227f};

const CGFloat groupTextColor[] = {0.615f, 0.635f, 0.69f};

using CernAPP::ItemStyle;

namespace CernAPP {

//________________________________________________________________________________________
void DrawFrame(CGContextRef ctx, const CGRect &rect, CGFloat rgbShift)
{
   assert(ctx != nullptr && "DrawFrame, parameter 'ctx' is null");

   CGContextSetAllowsAntialiasing(ctx, false);
   //Bright line at the top.
   CGContextSetRGBStrokeColor(ctx, frameTopLineColor[0] + rgbShift, frameTopLineColor[1] + rgbShift, frameTopLineColor[2] + rgbShift, 1.f);
   CGContextMoveToPoint(ctx, 0.f, 1.f);
   CGContextAddLineToPoint(ctx, rect.size.width, 1.f);
   CGContextStrokePath(ctx);
   
   //Dark line at the bottom.
   CGContextSetRGBStrokeColor(ctx, frameBottomLineColor[0] + rgbShift, frameBottomLineColor[1] + rgbShift, frameBottomLineColor[2] + rgbShift, 1.f);
   CGContextMoveToPoint(ctx, 0.f, rect.size.height);
   CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height);
   CGContextStrokePath(ctx);
   
   CGContextSetAllowsAntialiasing(ctx, true);
}

}

namespace {

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


@implementation MenuItemView {
   ItemStyle itemStyle;

   //Weak, we do not have to control life time of these objects.
   __weak NSObject<MenuItemProtocol> *menuItem;
   __weak MenuViewController *controller;

   UILabel *itemLabel;
}

@synthesize isSelected;

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame item : (NSObject<MenuItemProtocol> *) anItem
       style : (CernAPP::ItemStyle) aStyle controller : (MenuViewController *) aController
{
   assert(aStyle == ItemStyle::standalone || aStyle == ItemStyle::separator || aStyle == ItemStyle::child &&
          "initWithFrame:item:style:controller:, parameter 'aStyle' is invalid");
   assert(aStyle == ItemStyle::separator || anItem &&
          "initWithFrame:item:style:controller:, parameter 'anItem' is nil and style is not a separator");
   assert(aController != nil && "initWithFrame:item:style:controller:, parameter 'aController' is nil");

   if (self = [super initWithFrame : frame]) {
      menuItem = anItem;
      itemStyle = aStyle;
      controller = aController;
      
      if (aStyle != ItemStyle::separator) {//Separator is simply a blank row in a menu.
         UITapGestureRecognizer * const tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget : self action : @selector(handleTap)];
         [tapRecognizer setNumberOfTapsRequired : 1];
         [self addGestureRecognizer : tapRecognizer];
         
         itemLabel = [[UILabel alloc] initWithFrame : CGRect()];
         itemLabel.text = menuItem.itemText;

         UIFont * const font = [UIFont fontWithName : CernAPP::childMenuFontName size : childMenuItemFontSize];
         assert(font != nil && "initWithFrame:item:style:controller:, font not found");
         itemLabel.font = font;
      
         itemLabel.textAlignment = NSTextAlignmentLeft;
         itemLabel.numberOfLines = 1;
         itemLabel.clipsToBounds = YES;
         itemLabel.backgroundColor = [UIColor clearColor];
         
         using CernAPP::childTextColor;
         itemLabel.textColor = [UIColor colorWithRed : childTextColor[0] green : childTextColor[1] blue : childTextColor[2] alpha : 1.f];

         [self addSubview : itemLabel];
      }
      
      isSelected = NO;
   }
   
   return self;
}

//________________________________________________________________________________________
- (void) drawRect : (CGRect) rect
{
   CGContextRef ctx = UIGraphicsGetCurrentContext();
   
   //For a separator - simply fill a rectangle with a gradient.
   if (itemStyle == ItemStyle::separator) {
      GradientFillRect(ctx, rect, groupMenuFillColor[0]);
   } else {   
      if (!isSelected) {
         using CernAPP::childMenuFillColor;
         CGContextSetRGBFillColor(ctx, childMenuFillColor[0], childMenuFillColor[1], childMenuFillColor[2], 1.f);
         CGContextFillRect(ctx, rect);
         
         CernAPP::DrawFrame(ctx, rect, 0.f);
      } else {
         const CGFloat colors[][4] = {{0.f, 0.564f, 0.949f, 1.f}, {0.f, 0.431f, .901, 1.f}};
         GradientFillRect(ctx, rect, colors[0]);
      }
      
      if (menuItem.itemImage) {
         const CGSize imageSize = menuItem.itemImage.size;
         const CGFloat ratio = imageSize.width / imageSize.height;
      
         using CernAPP::childMenuItemTextIndent;
         
         CGFloat x = childMenuItemTextIndent;
         if (menuItem.menuGroup.parentGroup)
            x += childMenuItemTextIndent;
         
         [menuItem.itemImage drawInRect:CGRectMake(x, self.frame.size.height / 2 - childMenuItemImageSize / 2,
                                                   childMenuItemImageSize * ratio, childMenuItemImageSize)];
      }
   }
}

//________________________________________________________________________________________
- (void) layoutText
{
   if (itemStyle == ItemStyle::separator)
      return;

   using CernAPP::childMenuItemTextIndent;

   CGRect frame = self.frame;
   frame.origin.x = childMenuItemTextIndent;
   
   frame.origin.y = frame.size.height / 2 - childMenuItemTextHeight / 2;
   frame.size.width -= 2 * childMenuItemTextIndent;
   
   if (menuItem.menuGroup.parentGroup) {
      frame.origin.x = 2 * childMenuItemTextIndent;
      frame.size.width -= childMenuItemTextIndent * 2;
   }
   
   if (menuItem.itemImage) {
      const CGSize imageSize = menuItem.itemImage.size;
      const CGFloat addW = (imageSize.width / imageSize.height) * childMenuItemImageSize;
   
      frame.origin.x += addW + 4.f;
      frame.size.width -= addW + 4.f;
   }
   
   frame.size.height = childMenuItemTextHeight;

   itemLabel.frame = frame;
}

//________________________________________________________________________________________
- (void) handleTap
{
   [controller itemViewWasSelected : self];
   [menuItem itemPressedIn : controller];
}

@end

@implementation MenuItemsGroupView {
   __weak MenuItemsGroup *groupItem;
   __weak MenuViewController *menuController;
   
   UILabel *itemLabel;
   UIImageView *discloseImageView;
}

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect)frame item : (MenuItemsGroup *) item controller : (MenuViewController *) controller
{
   assert(item != nil && "initWithFrame:item:controller:, parameter 'item' is nil");
   assert(controller != nil && "initWithFrame:item:controller:, parameter 'controller' is nil");
   
   if (self = [super initWithFrame : frame]) {
      groupItem = item;
      menuController = controller;
      
      UITapGestureRecognizer * const tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget : self action : @selector(handleTap)];
      [tapRecognizer setNumberOfTapsRequired : 1];
      [self addGestureRecognizer : tapRecognizer];
      
      itemLabel = [[UILabel alloc] initWithFrame:CGRect()];
      [self addSubview : itemLabel];
      itemLabel.text = item.itemText;
      
      UIFont *font = nil;
      if (!groupItem.parentGroup)
         font = [UIFont fontWithName : groupMenuFontName size : groupMenuItemFontSize];
      else
         font = [UIFont fontWithName : CernAPP::childMenuFontName size : childMenuItemFontSize];

      assert(font != nil && "initWithFrame:item:controller:, font not found");
      itemLabel.font = font;

      
      itemLabel.textAlignment = NSTextAlignmentLeft;
      itemLabel.numberOfLines = 1;
      itemLabel.clipsToBounds = YES;
      itemLabel.backgroundColor = [UIColor clearColor];
      
      if (!groupItem.parentGroup)
         itemLabel.textColor = [UIColor colorWithRed : groupTextColor[0] green : groupTextColor[1] blue : groupTextColor[2] alpha : 1.f];
      else {
         using CernAPP::childTextColor;
         itemLabel.textColor = [UIColor colorWithRed : childTextColor[0] green : childTextColor[1] blue : childTextColor[2] alpha : 1.f];
      }

      itemLabel.layer.shadowColor = [UIColor blackColor].CGColor;
      itemLabel.layer.shadowOffset = menuTextShadowOffset;
      itemLabel.layer.shadowOpacity = menuTextShadowAlpha;
      
      if (groupItem.parentGroup)//Nested group.
         discloseImageView = [[UIImageView alloc] initWithImage : [UIImage imageNamed : @"disclose_child.png"]];
      else
         discloseImageView = [[UIImageView alloc] initWithImage : [UIImage imageNamed : @"disclose.png"]];

      discloseImageView.clipsToBounds = YES;
      discloseImageView.contentMode = UIViewContentModeScaleAspectFill;
      
      [self addSubview : discloseImageView];
   }
   
   return self;
}

//________________________________________________________________________________________
- (void) drawRect : (CGRect) rect
{
   CGContextRef ctx = UIGraphicsGetCurrentContext();

   if (groupItem.parentGroup) {
      //We have a different look & fill for a nested group:
      //it looks like a child menu item, but with a disclose arrow
      //and with a shifted image (if any) and title.
      using CernAPP::childMenuFillColor;
      CGContextSetRGBFillColor(ctx, childMenuFillColor[0], childMenuFillColor[1], childMenuFillColor[2], 1.f);
      CGContextFillRect(ctx, rect);
      CernAPP::DrawFrame(ctx, rect, 0.f);
      
      if (groupItem.itemImage) {
         const CGRect frame = self.frame;//can it be different from the 'rect' parameter???
         const CGSize imageSize = groupItem.itemImage.size;
         const CGFloat ratio = imageSize.width / imageSize.height;
         const CGRect imageRect = {CernAPP::childMenuItemTextIndent, frame.size.height / 2 - childMenuItemImageSize / 2,
                                   childMenuItemImageSize * ratio, childMenuItemImageSize};
         
         [groupItem.itemImage drawInRect : imageRect];

      }
   } else {
      GradientFillRect(ctx, rect, groupMenuFillColor[0]);
      //Dark line at the bottom.
      CGContextSetRGBStrokeColor(ctx, frameBottomLineColor[0], frameBottomLineColor[1], frameBottomLineColor[2], 1.f);
      CGContextMoveToPoint(ctx, 0.f, rect.size.height);
      CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height);
      CGContextStrokePath(ctx);
      
      if (groupItem.itemImage) {
         const CGRect frame = self.frame;//can it be different from the 'rect' parameter???
         const CGRect imageRect = CGRectMake(4.f, frame.size.height / 2 - menuItemImageSize / 2,
                                             menuItemImageSize, menuItemImageSize);
         [groupItem.itemImage drawInRect : imageRect];
      }
      
   }
}

//________________________________________________________________________________________
- (void) layoutText
{
   CGRect frame = self.frame;
   
   if (!groupItem.parentGroup) {
      if (groupItem.itemImage)
         frame.origin.x = menuItemImageSize + 8.f;
      else
         frame.origin.x = groupMenuItemTextIndent;
      
      frame.size.width -= frame.origin.x + groupMenuItemLeftMargin;//Not very smart, but ok.
      frame.origin.y = frame.size.height / 2 - groupMenuItemTextHeight / 2;
      frame.size.height = groupMenuItemTextHeight;
   } else {
      frame.origin.x = CernAPP::childMenuItemTextIndent;
      
      if (groupItem.itemImage) {
         const CGSize imageSize = groupItem.itemImage.size;
         const CGFloat addW = (imageSize.width / imageSize.height) * childMenuItemImageSize;
         frame.origin.x += addW + 4.f;
      }
      
      frame.size.width -= frame.origin.x + groupMenuItemLeftMargin;
      frame.origin.y = frame.size.height / 2 - CernAPP::childMenuItemTextIndent / 2;
      frame.size.height = childMenuItemTextHeight;
   }
   
   itemLabel.frame = frame;
   discloseImageView.frame = CGRectMake(frame.origin.x + frame.size.width, self.frame.size.height / 2 - discloseTriangleSize / 2, discloseTriangleSize, discloseTriangleSize);
}

//________________________________________________________________________________________
- (MenuItemsGroup *) menuItemsGroup
{
   return groupItem;
}

//________________________________________________________________________________________
- (UIImageView *) discloseImageView
{
   return discloseImageView;
}

//________________________________________________________________________________________
- (void) handleTap
{
   //Collapse or expand.
   [menuController groupViewWasTapped : self];
}

@end


@implementation MenuTableItemView

@synthesize imageView, textLabel, appearance, frameView, rowIndex;

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame
{
   //frame is not important (and in most cases 'invalid'):
   // view's geometry is set externally later.

   if (self = [super initWithFrame : frame]) {
      //
      self.backgroundColor = [UIColor whiteColor];

      imageView = [[UIImageView alloc] initWithFrame : frame];
      [self addSubview : imageView];
      
      frameView = [[UIView alloc] initWithFrame : frame];
      frameView.backgroundColor = [UIColor colorWithRed : 0.96 green : 0.96 blue : 0.96 alpha : 0.8f];
      frameView.layer.borderColor = [UIColor colorWithRed : 0.456f green : 0.472f blue : 0.492f alpha : 0.5f].CGColor;
      frameView.layer.borderWidth = 1.f;

      [self addSubview : frameView];
      
      textLabel = [[UILabel alloc] initWithFrame : frame];
      textLabel.backgroundColor = [UIColor clearColor];
      textLabel.font = [UIFont fontWithName : groupMenuFontName size : 16.f];
      textLabel.textColor = [UIColor colorWithRed : 0.341 green : 0.419 blue : 0.584 alpha : 1.f];
      textLabel.textAlignment = NSTextAlignmentCenter;
      //font
      //text color
      
      [frameView addSubview : textLabel];
   }
   
   return self;
}

@end

const CGFloat highlightCellColor[] = {0.f, 0.564f, 0.949f, 1.f};

namespace CernAPP {

//________________________________________________________________________________________
void HiglightCell(MenuTableItemView *cell, bool highlight)
{
   assert(cell != nil && "HighlightCell, parameter 'cell' is nil");
   
   if (!highlight) {
      cell.layer.shadowColor = [UIColor blackColor].CGColor;
      cell.backgroundColor = [UIColor whiteColor];
   } else {
      cell.backgroundColor = [UIColor colorWithRed : highlightCellColor[0] green : highlightCellColor[1] blue : highlightCellColor[2] alpha : 0.3f];
      cell.layer.shadowColor = [UIColor blueColor].CGColor;
   }
}

//________________________________________________________________________________________
void SetCellLayout(MenuTableItemView *cell, const CGRect &frameHint, CGFloat currentY)
{
   assert(cell != nil && "SetCellLayou, parameter 'cell' is nil");

   const CGFloat x = 10.f;
   const CGFloat margin = 5.f;
   const CGFloat textH = 40.f;
   const CGFloat imageH = 100.f;

   CGRect newFrame = frameHint;
   newFrame.origin.y = currentY;
   newFrame.origin.x = x;
   newFrame.size.width -= 2 * x;
      
   CGRect nestedFrame = {};
   nestedFrame.origin.x = margin;
   nestedFrame.origin.y = margin;
      
   if (cell.appearance == CellAppearance::withSquareImage) {
      newFrame.size.height = 120.f;
      
      nestedFrame.size.width = newFrame.size.height - 2 * margin;
      nestedFrame.size.height = nestedFrame.size.width;
      cell.imageView.frame = nestedFrame;
      
      nestedFrame.origin.x = nestedFrame.origin.x + nestedFrame.size.width + margin;
      nestedFrame.size.width = newFrame.size.width - nestedFrame.size.width - 2 * margin - margin;
      cell.frameView.frame = nestedFrame;
      
      nestedFrame.origin.x = margin;

      nestedFrame.origin.y = nestedFrame.size.height / 2 - textH / 2;

      nestedFrame.size.height = textH;
      nestedFrame.size.width -= 2 * margin;
      
      cell.textLabel.frame = nestedFrame;
   } else {
      newFrame.size.height = imageH + textH + 3 * margin;
      
      nestedFrame.size.height = imageH;
      nestedFrame.size.width = newFrame.size.width - 2 * margin;
      cell.imageView.frame = nestedFrame;
      
      nestedFrame.origin.y = nestedFrame.origin.y + nestedFrame.size.height + margin;
      nestedFrame.size.height = textH;
      cell.frameView.frame = nestedFrame;
   
      nestedFrame.origin.x = margin;
      nestedFrame.origin.y = 0.f;
      nestedFrame.size.width -= 2 * margin;
      cell.textLabel.frame = nestedFrame;
   }
   
   cell.frame = newFrame;
}

//________________________________________________________________________________________
void SetCellLayer(MenuTableItemView *view)
{
   assert(view != nil && "SetCellLayer, parameter 'cell' is nil");
   
   view.layer.cornerRadius = 6.f;
   view.layer.shadowColor = [UIColor darkGrayColor].CGColor;
   view.layer.shadowOpacity = 0.5f;
   view.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
   
   CGRect newFrame = view.frame;
   newFrame.origin = CGPointZero;
   view.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect : newFrame cornerRadius : 6.f].CGPath;
   view.layer.borderColor = [UIColor colorWithRed : 0.456f green : 0.472f blue : 0.492f alpha : 0.5f].CGColor;
   view.layer.borderWidth = 1.f;
}

}
