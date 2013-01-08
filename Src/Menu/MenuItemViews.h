//
//  MenuItemViews.h
//  slide_menu
//
//  Created by Timur Pocheptsov on 1/7/13.
//  Copyright (c) 2013 Timur Pocheptsov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MenuItems.h"

namespace CernAPP {

enum class ItemStyle {
   standalone,
   child,
   separator
};

void DrawFrame(CGContextRef ctx, const CGRect &rect);

}

@class MenuViewController;

@interface MenuItemView : UIView

- (id) initWithFrame : (CGRect) frame item : (NSObject<MenuItemProtocol> *) item
       style : (CernAPP::ItemStyle) style controller : (MenuViewController *) controller;
- (void) drawRect : (CGRect) rect;

- (void) layoutText;

@property (nonatomic) BOOL isSelected;

@end

//This is a group title.
@interface MenuItemsGroupView : UIView

- (id) initWithFrame : (CGRect) frame item : (MenuItemsGroup *) item
       controller : (MenuViewController *) controller;
- (void) drawRect : (CGRect)rect;

- (void) layoutText;

- (MenuItemsGroup *) menuItemsGroup;
- (UIImageView *) discloseImageView;

@end

