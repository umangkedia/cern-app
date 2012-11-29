//
//  Created by Timur Pocheptsov on 11/7/12.
//  Copyright (c) 2012 Timur Pocheptsov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScrollSelectorDelegate.h"


@class NewsTableViewController;
//
//News table views are placed in a scroll view (we can have different feeds).
//User can either scroll pages in such a view or use "scroll-wheel" widget at the top of a view.
//

@interface MultiPageController : UIViewController<ScrollSelectorDelegate, UIScrollViewDelegate>

- (void) setItems : (NSMutableArray *) items;
- (void) addPageFor : (NewsTableViewController *) controller;
- (void) preparePagesFor : (NSMutableArray *) itemNames;
- (void) selectPage : (NSInteger) page;

@end
