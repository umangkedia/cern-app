//
//  Created by Timur Pocheptsov on 11/7/12.
//  Copyright (c) 2012 Timur Pocheptsov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScrollSelectorDelegate.h"
#import "PageControllerProtocol.h"

//
//Different news feeds, live event images, etc. - are placed
//as a separate pages in a scroll view of a multipage view controller.
//Pages can be scrolled as usually or by scrolling
//small "wheel-like" selector at the top of the page -
//scroll selector.
//This controller is for iPhone/iPod Touch only.
//

@interface MultiPageController : UIViewController<ScrollSelectorDelegate, UIScrollViewDelegate>

- (void) setNewsFeedControllersFor : (NSMutableArray *) items;

//This is a bit clumsy: controller can contain not feed tables only,
//but something else. Still, this function is called to: 1) set
//names for all future pages and 2) change the geometry/content size of
//a navigation view to be able to host these pages.
- (void) setupControllerForPages : (NSMutableArray *) pageNames;
//Now we add pages one by one (title should be set by a previous method.
- (void) addPageFor : (UIViewController<PageController> *) controller;

- (void) scrollToPage : (NSInteger) page;
- (void) hideBackButton : (BOOL) hide;

//ScrollSelectorDelegate protocol:
- (void) item : (NSUInteger) item selectedIn : (ScrollSelector *) selector;

- (UIViewController<PageController> *) selectedViewController;

@end
