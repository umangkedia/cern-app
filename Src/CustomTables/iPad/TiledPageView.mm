//
//  TiledPageView.m
//  CERN
//
//  Created by Timur Pocheptsov on 3/18/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <algorithm>
#import <cassert>

#import <QuartzCore/QuartzCore.h>

#import "TiledPageView.h"
#import "TileView.h"

const NSUInteger shiftPart = 2;

@implementation TiledPageView {
   NSMutableArray *tiles;
}

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame
{
   if (self = [super initWithFrame : frame]) {
      //
   }

   return self;
}

//________________________________________________________________________________________
- (void) setPageItems : (NSArray *) feedItems startingFrom : (NSUInteger) index
{
   assert(feedItems != nil && "setPageItems:startingFrom:, parameter 'feedItems' is nil");
   assert(index < feedItems.count && "setPageItems:startingFrom:, parameter 'index' is out of range");

   tiles = [[NSMutableArray alloc] init];

   const NSUInteger endOfRange = std::min(feedItems.count, index + 6);
   
   for (NSUInteger i = index; i < endOfRange; ++i) {
      TileView *newTile = [[TileView alloc] initWithFrame : CGRect()];
      [newTile setTileData : (MWFeedItem *)feedItems[i]];
      [tiles addObject : newTile];
      [self addSubview : newTile];
   }
}


//________________________________________________________________________________________
- (void) setThumbnail : (UIImage *) thumbnailImage forTile : (NSUInteger) tileIndex
{
   assert(thumbnailImage != nil && "setThumbnail:forTile, parameter 'thumbnailImage' is nil");
   assert(tileIndex < tiles.count && "setThumbnail:forTile, parameter 'tileIndex' is out of range");
   
   TileView * const tile = (TileView *)tiles[tileIndex];
   [tile setTileThumbnail : thumbnailImage];
}

//________________________________________________________________________________________
- (void) layoutTiles
{
   if (!tiles.count)
      return;

   //Layout tiles
   const CGRect frame = self.frame;
   //We always place 6 tiles on the page (if we have 6).

   //Hehe, can I, actually, use this to identify landscape orientation???
   const NSUInteger nItemsPerRow = frame.size.width > frame.size.height ? 3 : 2;
   const NSUInteger nRows = nItemsPerRow == 3 ? 2 : 3;
   const CGFloat width = frame.size.width / nItemsPerRow;
   const CGFloat height = frame.size.height / nRows;
   
   NSUInteger index = 0;
   for (TileView *tile in tiles) {
      const CGFloat x = (index % nItemsPerRow) * width + 2.f;
      const CGFloat y = (index / nItemsPerRow) * height + 2.f;
      const CGRect frame = CGRectMake(x, y, width - 4.f, height - 4.f);

      tile.frame = frame;
      [tile layoutTile];
      
      ++index;
   }
}

//________________________________________________________________________________________
- (void) explodeTiles : (UIInterfaceOrientation) orientation
{
   const NSUInteger nItemsPerRow = UIInterfaceOrientationIsLandscape(orientation) ? 3 : 2;
   const NSUInteger nRows = nItemsPerRow == 3 ? 2 : 3;

   const CGFloat width = self.frame.size.width / nItemsPerRow;
   const CGFloat height = self.frame.size.height / nRows;

   NSUInteger index = 0;
   for (TileView *tile in tiles) {
      const NSUInteger col = index % nItemsPerRow;
      const NSUInteger row = index / nItemsPerRow;
      CGFloat x = col * width;
      CGFloat y = row * height;
      CGRect frame = {};
      frame.size.width = width - 4;
      frame.size.height = height - 4;
      
      if (!col)
         x -= width / shiftPart;
      else if (col + 1 == nItemsPerRow)
         x += width / shiftPart;

      if (!row)
         y -= height / shiftPart;
      else if (row + 1 == nRows)
         y += height / shiftPart;
      
      frame.origin = CGPointMake(x, y);
      tile.frame = frame;
      tile.layer.frame = frame;
      [tile layoutTile];
      ++index;
   }
}

//________________________________________________________________________________________
- (void) collectTilesAnimatedForOrientation : (UIInterfaceOrientation) orientation from : (CFTimeInterval) start withDuration : (CFTimeInterval) duration
{
   const NSUInteger nItemsPerRow = UIInterfaceOrientationIsLandscape(orientation) ? 3 : 2;
   const NSUInteger nRows = nItemsPerRow == 3 ? 2 : 3;

   const CGFloat width = self.frame.size.width / nItemsPerRow;
   const CGFloat height = self.frame.size.height / nRows;

   NSUInteger index = 0;
   for (TileView *tile in tiles) {   
      const NSUInteger col = index % nItemsPerRow;
      const NSUInteger row = index / nItemsPerRow;

      const CGPoint startPoint = tile.layer.position;
      CGPoint endPoint = startPoint;
      
      if (!col)
         endPoint.x += width / shiftPart;
      else if (col + 1 == nItemsPerRow)
         endPoint.x -= width / shiftPart;

      if (!row)
         endPoint.y += height / shiftPart;
      else if (row + 1 == nRows)
         endPoint.y -= height / shiftPart;
      
      CABasicAnimation * const animation = [CABasicAnimation animationWithKeyPath : @"position"];
      animation.fromValue = [NSValue valueWithCGPoint : startPoint];
      animation.toValue = [NSValue valueWithCGPoint : endPoint];
      animation.beginTime = start;
      [animation setTimingFunction : [CAMediaTimingFunction functionWithControlPoints : 0.6f : 1.5f : 0.8f : 0.8f]];

      animation.duration = duration;
      [tile.layer addAnimation : animation forKey : [NSString stringWithFormat : @"bounce%u", index]];
      tile.layer.position = endPoint;
      //
      ++index;
   }
}

@end
