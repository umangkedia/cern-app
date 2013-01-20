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

}

@class MenuViewController;

@interface MenuItemView : UIView

- (id) initWithFrame : (CGRect) frame item : (NSObject<MenuItemProtocol> *) item
       style : (CernAPP::ItemStyle) style controller : (MenuViewController *) controller;
- (void) drawRect : (CGRect) rect;

- (void) layoutText;

@property (nonatomic) BOOL isSelected;
@property (nonatomic) CernAPP::ItemStyle itemStyle;

@property (nonatomic) CGFloat indent;
@property (nonatomic) CGSize imageHint;

@end

//This is a group title.
@interface MenuItemsGroupView : UIView

- (id) initWithFrame : (CGRect) frame item : (MenuItemsGroup *) item
       controller : (MenuViewController *) controller;
- (void) drawRect : (CGRect)rect;

- (void) layoutText;

@property (nonatomic) CGFloat indent;
@property (nonatomic) CGSize imageHint;

- (MenuItemsGroup *) menuItemsGroup;
- (UIImageView *) discloseImageView;

@end



