//
//  TiledPageView.h
//  CERN
//
//  Created by Timur Pocheptsov on 3/18/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TiledPageView : UIView

- (void) setPageItems : (NSArray *) feedItems startingFrom : (NSUInteger) index;

@end
