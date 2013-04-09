//
//  TiledPageView.h
//  CERN
//
//  Created by Timur Pocheptsov on 3/18/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TiledPageView : UIView

@property (nonatomic) NSUInteger pageNumber;

- (void) setPageItems : (NSArray *) feedItems startingFrom : (NSUInteger) index;
- (void) setPageItemsFromCache : (NSArray *) cache startingFrom : (NSUInteger) index;
- (void) setThumbnail : (UIImage *) thumbnailImage forTile : (NSUInteger) tileIndex;
- (BOOL) tileHasThumbnail : (NSUInteger) tileIndex;

- (void) layoutTiles;

//Animations:
- (void) explodeTiles : (UIInterfaceOrientation) orientation;
//Actually, both CFTimeInterval and NSTimeInterval are typedefs for double.
- (void) collectTilesAnimatedForOrientation : (UIInterfaceOrientation) orientation from : (CFTimeInterval) start withDuration : (CFTimeInterval) duration;

@end
