//
//  TileView.h
//  CERN
//
//  Created by Timur Pocheptsov on 3/18/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MWFeedItem.h"

@interface TileView : UIView

- (void) setTileData : (MWFeedItem *) feedItem;
- (void) setTileTitle : (NSString *) title summary : (NSString *) summary
         date : (NSDate *) date link : (NSString *) link;
- (void) setTileThumbnail : (UIImage *) image;
- (BOOL) hasThumbnail;
- (void) layoutTile;

@end

namespace CernAPP {

extern NSString * const tileSelectionNotification;

}
