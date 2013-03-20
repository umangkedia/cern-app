//
//  TileView.m
//  CERN
//
//  Created by Timur Pocheptsov on 3/18/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <cassert>
#import <cstdlib>

#import <CoreText/CoreText.h>

#import "PictureButtonView.h"
#import "NewsTableViewCell.h"
#import "NSString+HTML.h"
#import "TileView.h"

namespace {

//Different geometry constants, all in percents.
const CGFloat wideImageMargin = 0.08;

const CGFloat titleH = 0.18f;
const CGFloat footerY = 0.9f;
const CGFloat textH = footerY - titleH;
const CGFloat wideImageH = 0.5 * textH;

const CGFloat upCutH = 0.2;
const CGFloat downCutH = textH - upCutH;


//________________________________________________________________________________________
bool IsWideImage(UIImage *image)
{
   assert(image != nil && "IsWideImage, parameter 'image' is nil");

   const CGSize imageSize = image.size;

   if (!imageSize.width || !imageSize.height)
      return false;

   return imageSize.width / imageSize.height >= 2.f;
}

}

@implementation TileView {
   UIImageView *thumbnailView;
   NSMutableAttributedString * title;
   NSMutableAttributedString * text;
   
   CTFrameRef titleFrame;
   CTFrameRef textFrame;
   
   bool wideImageOnTop;
   int imageCut;
   
   UILabel *infoLabel;//Article's date and author.

   PictureButtonView *actionButton;
}

//________________________________________________________________________________________
- (CGFloat) translateY : (CGFloat) y
{
   return self.frame.size.height - y;
}

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame
{
   if (self = [super initWithFrame : frame]) {
      thumbnailView = [[UIImageView alloc] initWithFrame : CGRect()];
      thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
      thumbnailView.clipsToBounds = YES;
      [self addSubview : thumbnailView];
      
      self.backgroundColor = [UIColor whiteColor];
      
      titleFrame = nullptr;
      textFrame = nullptr;
      
      wideImageOnTop = std::rand() % 2;
      imageCut = std::rand() % 4;
      
      infoLabel = [[UILabel alloc] initWithFrame : CGRect()];
      infoLabel.textColor = [[UIColor blueColor] colorWithAlphaComponent : 0.5];
      UIFont * const font = [UIFont fontWithName : [NewsTableViewCell authorLabelFontName] size : 14.f];
      assert(font != nil && "initWithFrame, custom font is nil");
      infoLabel.font = font;
      [self addSubview : infoLabel];
      
      actionButton = [[PictureButtonView alloc] initWithFrame:CGRect() image : [UIImage imageNamed : @"action_blue.png"]];
      [actionButton addTarget : self selector : @selector(sendArticle)];
      [self addSubview : actionButton];
   }

   return self;
}

//________________________________________________________________________________________
- (void) dealloc
{
   if (titleFrame)
      CFRelease(titleFrame);
   
   if (textFrame)
      CFRelease(textFrame);
}

//________________________________________________________________________________________
- (void) setTileData : (MWFeedItem *) feedItem
{
   assert(feedItem != nil && "setTileData:, parameter 'feedItem' is nil");
   
   title = [[NSMutableAttributedString alloc] initWithString : feedItem.title ? [feedItem.title stringByConvertingHTMLToPlainText] : @"No title ... "];

   NSDateFormatter * const dateFormatter = [[NSDateFormatter alloc] init];
   [dateFormatter setDateFormat:@"d MMM. yyyy"];
   infoLabel.text = [dateFormatter stringFromDate : feedItem.date ? feedItem.date : [NSDate date]];

   //Let's now set attributes:   
   //1. Font.
   UIFont * const titleFont = [UIFont fontWithName : @"PTSans-Bold" size : 20.f];
   assert(titleFont != nil && "setTileData:, titles' font is nil");
   const NSRange titleRange = NSMakeRange(0, title.length);
   [title addAttribute : NSFontAttributeName value : titleFont range : titleRange];
   
   //2. Text alignment.
   NSMutableParagraphStyle * const style = [[NSMutableParagraphStyle alloc] init];
   [style setAlignment : NSTextAlignmentCenter];
   [title addAttribute : NSParagraphStyleAttributeName value : style range : titleRange];
   
   text = [[NSMutableAttributedString alloc] initWithString : feedItem.summary ? [feedItem.summary stringByConvertingHTMLToPlainText] : @""];
   //Let's set text attributes:
   
   //1. Font.
   UIFont * const textFont = [UIFont fontWithName : @"PTSans-Caption" size : 16.f];
   assert(textFont != nil && "setTileData:, text's font is nil");
   const NSRange textRange = NSMakeRange(0, text.length);
   [text addAttribute : NSFontAttributeName value : textFont range : textRange];
   //2. Color
   [text addAttribute : NSForegroundColorAttributeName value : [UIColor darkGrayColor] range : textRange];
   //3. Alignment.
   NSMutableParagraphStyle * const textStyle = [[NSMutableParagraphStyle alloc] init];
   [textStyle setAlignment : NSTextAlignmentNatural];//NSTextAlignmentJustified];
   [textStyle setLineBreakMode : NSLineBreakByCharWrapping];
   [text addAttribute : NSParagraphStyleAttributeName value : textStyle range : textRange];
}

//________________________________________________________________________________________
- (void) setTileThumbnail:(UIImage *) image
{
   assert(image != nil && "setTileThumbnail, parameter 'image' is nil");
   thumbnailView.image = image;
   [self layoutTile];
}

//________________________________________________________________________________________
- (CGPathRef) createTextPath
{
   const CGFloat w = self.frame.size.width;
   const CGFloat h = self.frame.size.height;

   if (!thumbnailView.image) {
      //The simplest possible case.
      CGRect textRect = CGRectMake(wideImageMargin * w, [self translateY : titleH * h + textH * h], w - 2 * wideImageMargin * w, h * textH);

      return CGPathCreateWithRect(textRect, &CGAffineTransformIdentity);
   } else if (IsWideImage(thumbnailView.image)) {
      CGRect textRect = {};
      if (wideImageOnTop)
         textRect = CGRectMake(wideImageMargin * w, [self translateY : titleH * h + textH * h], w - 2 * wideImageMargin * w, 0.5f * h * textH);
      else
         textRect = CGRectMake(wideImageMargin * w, [self translateY : titleH * h + 0.5f * textH * h], w - 2 * wideImageMargin * w, 0.5f * h * textH);

      return CGPathCreateWithRect(textRect, &CGAffineTransformIdentity);
      //Layout image view!
   } else {
      CGMutablePathRef path = CGPathCreateMutable();
      const CGFloat y1 = [self translateY : textH * h * 0.5f + titleH * h];
      const CGFloat y2 = [self translateY : textH * h + titleH * h];
   
      //At the beginning I was adding rectangle sub-paths, but ...
      //there is a visible gap between text in these rectangles.

      switch (imageCut) {
      case 0 :
         CGPathMoveToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y2);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y1);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y1);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y1 + textH * 0.5 * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w - w * wideImageMargin, y1 + textH * 0.5 * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w - w * wideImageMargin, y2);
         CGPathCloseSubpath(path);
         break;
      case 1:
         CGPathMoveToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y2);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y2 + textH * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y2 + textH * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y1);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w - w * wideImageMargin, y1);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w - w * wideImageMargin, y2);
         CGPathCloseSubpath(path);
         
         
         break;
      case 2:
         CGPathMoveToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y1);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y2 + textH * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w - w * wideImageMargin, y2 + textH * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w - w * wideImageMargin, y2);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y2);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y1);
         CGPathCloseSubpath(path);

         break;
      case 3:
         CGPathMoveToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y2);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, wideImageMargin * w, y2 + textH * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w -  w * wideImageMargin, y2 + textH * h);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w -  w * wideImageMargin, y1);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y1);
         CGPathAddLineToPoint(path, &CGAffineTransformIdentity, w / 2, y2);
         CGPathCloseSubpath(path);

         break;
      default:
         assert(0 && "createTextPathAndLayoutImage, unknown layout");
         break;
      }

      return path;
   }
}

//________________________________________________________________________________________
- (void) layoutTitle
{
   if (titleFrame)
      CFRelease(titleFrame);

   const CGFloat w = self.frame.size.width;
   const CGFloat h = self.frame.size.height;
   
   //Title frame is always simple.
   const CGRect titleRect = CGRectMake(0.f, [self translateY : titleH * h], w, h * titleH);
   CGPathRef titlePath = CGPathCreateWithRect(titleRect, &CGAffineTransformIdentity);
   CTFramesetterRef titleSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)title);
   titleFrame = CTFramesetterCreateFrame(titleSetter, CFRangeMake(0, [title length]), titlePath, nullptr);
   
   CGPathRelease(titlePath);
   CFRelease(titleSetter);
}

//________________________________________________________________________________________
- (void) layoutText
{
   if (textFrame)
      CFRelease(textFrame);

   CGPathRef textPath = [self createTextPath];
   if (textPath) {
      CTFramesetterRef textSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)text);
      textFrame = CTFramesetterCreateFrame(textSetter, CFRangeMake(0, [text length]), textPath, nullptr);
      CFRelease(textSetter);
      CFRelease(textPath);
   }
}

//________________________________________________________________________________________
- (void) layoutThumbnail
{
   if (thumbnailView.image) {
      const CGFloat w = self.frame.size.width;
      const CGFloat h = self.frame.size.height;

      if (IsWideImage(thumbnailView.image)) {
         CGRect imageRect = {};
         if (wideImageOnTop)
            imageRect = CGRectMake(wideImageMargin * w, titleH * h, w - 2 * wideImageMargin * w, 0.5f * h * textH);
         else
            imageRect = CGRectMake(wideImageMargin * w, titleH * h + textH * h * 0.5f, w - 2 * wideImageMargin * w, 0.5f * h * textH);

         thumbnailView.frame = imageRect;
      } else {
         switch (imageCut) {
         case 0:
            thumbnailView.frame = CGRectMake(wideImageMargin * w + 5, titleH * h + 5, (w - 2 * w * wideImageMargin) * 0.5 - 10, h * textH * 0.5 - 10);
            break;
         case 1:
            thumbnailView.frame = CGRectMake(w / 2 + 5, titleH * h + 5, (w - 2 * w * wideImageMargin) * 0.5 - 10, h * textH * 0.5 - 10);
            break;
         case 2:
            thumbnailView.frame = CGRectMake(wideImageMargin * w + 5, titleH * h + 5 + textH * 0.5 * h, (w - 2 * w * wideImageMargin) * 0.5 - 10, h * textH * 0.5 - 10);
            break;
         case 3:
            thumbnailView.frame = CGRectMake(w / 2 + 5, titleH * h + 5 + textH * 0.5 * h, (w - 2 * w * wideImageMargin) * 0.5 - 10, h * textH * 0.5 - 10);
            break;
         default:
            assert(0 && "layoutThumbnail, unknown layout");
            break;
         }
      }
   }
}

//________________________________________________________________________________________
- (void) layoutUIElements
{
   const CGFloat hugeH = 1000.f;
   const CGSize viewSize = self.frame.size;
   const CGSize dateSize = [infoLabel.text sizeWithFont : infoLabel.font constrainedToSize : CGSizeMake(viewSize.width / 2, hugeH)];
   const CGFloat y = footerY * viewSize.height + (1 - footerY) * viewSize.height * 0.5 - dateSize.height / 2;
   infoLabel.frame = CGRectMake(wideImageMargin * viewSize.width, y, dateSize.width, dateSize.height);
   
   const CGFloat btnSz = (1 - footerY) * viewSize.height;//quite arbitrary choise
   actionButton.frame = CGRectMake(viewSize.width - btnSz, viewSize.height - btnSz, btnSz, btnSz);
}

//________________________________________________________________________________________
- (void) layoutTile
{
   [self layoutTitle];
   [self layoutText];
   [self layoutThumbnail];
   [self layoutUIElements];
   
   [self setNeedsDisplay];
}

//________________________________________________________________________________________
- (void) sendArticle
{
}

#pragma mark - text rendering.
//________________________________________________________________________________________
- (void) drawRect : (CGRect) rect
{
   [super drawRect : rect];
   
   CGContextRef ctx = UIGraphicsGetCurrentContext();

   CGContextSetRGBStrokeColor(ctx, 0.f, 0.f, 0.f, 1.f);

   CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
   CGContextTranslateCTM(ctx, 0, rect.size.height);
   CGContextScaleCTM(ctx, 1.f, -1.f);

   if (titleFrame)
      CTFrameDraw(titleFrame, ctx);
   
   if (textFrame)
      CTFrameDraw(textFrame, ctx);
}

@end
