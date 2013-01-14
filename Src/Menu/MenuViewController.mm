#import <cassert>
#import <cmath>

#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"
#import "MenuViewController.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"
#import "MenuItems.h"

using CernAPP::ItemStyle;

@implementation MenuViewController {
   NSMutableArray *menuItems;
   MenuItemView *selectedItemView;
   
   BOOL inAnimation;
   __weak MenuItemsGroup *newOpen;
}

//________________________________________________________________________________________
- (UIImage *) loadItemImage : (NSDictionary *) desc
{
   assert(desc != nil && "loadItemImage:, parameter 'desc' is nil");
   
   if (id objBase = desc[@"Image name"]) {
      assert([objBase isKindOfClass : [NSString class]] &&
             "loadItemImage:, 'Image name' must be a NSString");
      
      return [UIImage imageNamed : (NSString *)objBase];
   }
   
   return nil;
}

//________________________________________________________________________________________
- (void) setStateForGroup : (NSUInteger) groupIndex from : (NSDictionary *) desc
{
   assert(groupIndex < menuItems.count && "setStateForGroup:from:, parameter 'groupIndex' is out of bounds");
   assert([menuItems[groupIndex] isKindOfClass : [MenuItemsGroup class]] &&
          "setStateForGroup:from:, state can be set only for a sub-menu");
   assert(desc != nil && "setStateForGroup:from:, parameter 'desc' is nil");

   MenuItemsGroup * const group = (MenuItemsGroup *)menuItems[groupIndex];
   
   assert([desc[@"Expanded"] isKindOfClass : [NSNumber class]] &&
          "setStateForGroup:from:, 'Expanded' is not found or has a wrong type");
   
   const NSInteger val = [(NSNumber *)desc[@"Expanded"] integerValue];
   assert(!val || val == 1 || val == 2 && "setStateForGroup:from:, 'Expanded' can have a vlue only 0, 1 or 2");
   
   if (!val) {
      group.collapsed = YES;
      group.containerView.hidden = YES;
      group.titleView.discloseImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
   } else if (val == 1 || val == 2) {
      group.collapsed = NO;
      if (val == 2) {
         group.shrinkable = NO;
         group.titleView.discloseImageView.image = [UIImage imageNamed : @"disclose_disabled.png"];
      }
   }
}

//________________________________________________________________________________________
- (void) addMenuGroup : (NSString *) groupName withImage : (UIImage *) groupImage forItems : (NSMutableArray *) items
{
   assert(groupName != nil && "addMenuGroup:withImage:forItems:, parameter 'groupName' is nil");
   //groupImage can be nil, it's ok.
   assert(items != nil && "addMenuGroup:withImage:forItems:, parameter 'items' is nil");

   MenuItemsGroup * const group = [[MenuItemsGroup alloc] initWithTitle : groupName image : groupImage items : items];
   
   for (NSObject<MenuItemProtocol> *menuItem in items) {
      if ([menuItem isKindOfClass : [MenuItemsGroup class]]) {
         MenuItemsGroup *const nestedGroup = (MenuItemsGroup *)menuItem;
         nestedGroup.parentGroup = group;
         nestedGroup.collapsed = YES;//By default, nested sub-menu is closed.
      }
   }
   
   [group addMenuItemViewInto : scrollView controller : self];
   [menuItems addObject : group];
   
   for (NSObject<MenuItemProtocol> *menuItem in items) {
      if ([menuItem isKindOfClass : [MenuItemsGroup class]]) {
         MenuItemsGroup *const nestedGroup = (MenuItemsGroup *)menuItem;
         MenuItemsGroupView * const view = nestedGroup.titleView;
         nestedGroup.containerView.hidden = YES;
         view.discloseImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
      }
   }
}


//________________________________________________________________________________________
- (BOOL) loadNewsSection : (NSDictionary *) desc
{
   assert(scrollView != nil && "loadNewSection:, scrollView is not loaded yet!");
   assert(desc != nil && "loadNewsSection:, parameter 'desc' is nil");
   
   id objBase = desc[@"Category name"];
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadNewsSection:, either 'Category Name' not found, or it's not a NSString");
   
   NSString * const catName = (NSString *)objBase;
   if (![catName isEqualToString : @"News"])
      return NO;
   
   //Find a section name, it's a required property.
   objBase = desc[@"Name"];
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadNewsSection:, either 'Name' not found, or it's not a NSString");
   
   NSString * const sectionName = (NSString *)objBase;
   
   //Now, we need an array of either feeds or tweets.
   objBase = desc[@"Feeds"];
   if (objBase) {
      assert([objBase isKindOfClass:[NSArray class]] &&
             "loadNewsSection:, 'Feeds' must have a NSArray type");
      NSArray * const feeds = (NSArray *)objBase;

      if (feeds.count) {
         //Read news feeds.
         NSMutableArray * const items = [[NSMutableArray alloc] init];
         for (id info in feeds) {
            assert([info isKindOfClass : [NSDictionary class]] &&
                   "loadNewsSection, feed info must be a dictionary");
            NSDictionary * const feedInfo = (NSDictionary *)info;
            FeedProvider * const provider = [[FeedProvider alloc] initWith : feedInfo];
            MenuItem * const newItem = [[MenuItem alloc] initWithContentProvider : provider];
            [items addObject : newItem];
         }
         
         [self addMenuGroup : sectionName withImage : [self loadItemImage:desc] forItems : items];
         [self setStateForGroup : menuItems.count - 1 from : desc];
      }
   }

   return YES;
}

//________________________________________________________________________________________
- (BOOL) loadLIVESection : (NSDictionary *) desc
{
   assert(desc != nil && "loadLIVESection:, parameter 'desc' is nil");
   
   id objBase = desc[@"Category name"];
   assert(objBase != nil && "loadLIVESection:, 'Category Name' not found");
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadLIVESection:, 'Category Name' must have a NSString type");
   
   NSString * const catName = (NSString *)objBase;
   if (![catName isEqualToString : @"LIVE"])
      return NO;

   objBase = desc[@"Experiments"];
   assert(objBase != nil && "loadLIVESection:, 'Experiments' not found");
   assert([objBase isKindOfClass:[NSArray class]] &&
          "loadLIVESection:, 'Experiments' must have a NSArray type");
   
   NSArray * const experimentNames = (NSArray *)objBase;
   
   if (experimentNames.count) {
      NSMutableArray * const items = [[NSMutableArray alloc] init];
      for (id expBase in experimentNames) {
         //This is just an array of strings.
         assert([expBase isKindOfClass : [NSString class]] &&
                "loadLIVESection:, experiment's name must have a NSString type");
         
         MenuItemLIVE * liveItem = [[MenuItemLIVE alloc] initWithExperiment : (NSString *)expBase];
         [items addObject : liveItem];
      }

      [self addMenuGroup : @"LIVE" withImage : [self loadItemImage : desc] forItems : items];
      [self setStateForGroup : menuItems.count - 1 from : desc];
   }

   return YES;
}

//________________________________________________________________________________________
- (BOOL) loadStaticInfo : (NSDictionary *) desc
{
   assert(desc != nil && "loadStaticInfo, parameter 'desc' is nil");

   id objBase = desc[@"Category name"];
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadStaticInfo:, 'Category name' either not found or has a wrong type");
   
   if (![(NSString *)objBase isEqualToString : @"StaticInfo"])
      return NO;

   NSString * const path = [[NSBundle mainBundle] pathForResource : @"StaticInformation" ofType : @"plist"];
   NSDictionary * const plistDict = [NSDictionary dictionaryWithContentsOfFile : path];
   assert(plistDict != nil && "loadStaticInfo:, no dictionary or StaticInformation.plist found");

   objBase = plistDict[@"Root"];
   assert([objBase isKindOfClass : [NSArray class]] && "loadStaticInfo:, 'Root' not found or has a wrong type");
   //We have an array of dictionaries.
   NSArray * const entries = (NSArray *)objBase;
   
   if (entries.count) {
      //Items for a new group.
      NSMutableArray * const items = [[NSMutableArray alloc] init];
      for (objBase in entries) {
         assert([objBase isKindOfClass : [NSDictionary class]] &&
                "loadStaticInfo:, array of dictionaries expected");
         NSDictionary * const itemDict = (NSDictionary *)objBase;
         assert([itemDict[@"Items"] isKindOfClass : [NSArray class]] &&
                "loadStaticInfo:, 'Items' is either nil or has a wrong type");
         NSArray * const staticInfo = (NSArray *)itemDict[@"Items"];
         //Again, this must be an array of dictionaries.
         assert([staticInfo[0] isKindOfClass : [NSDictionary class]] &&
                "loadStaticInfo:, 'Items' must be an array of dictionaries");
         
         //Now we check, what do we have inside.
         NSDictionary * const firstItem = (NSDictionary *)staticInfo[0];
         if (firstItem[@"Items"]) {
            NSMutableArray * const subMenu = [[NSMutableArray alloc] init];
            for (id dictBase in staticInfo) {
               assert([dictBase isKindOfClass : [NSDictionary class]] &&
                      "loadStaticInfo:, array of dictionaries expected");
               MenuItemStaticInfo * const newItem = [[MenuItemStaticInfo alloc] initWithDictionary :
                                                     (NSDictionary *)dictBase];
               [subMenu addObject : newItem];
              
            }

            assert([itemDict[@"Title"] isKindOfClass : [NSString class]] &&
                   "loadStaticInfo:, 'Title' is either nil or has a wrong type");
            MenuItemsGroup * const newGroup = [[MenuItemsGroup alloc] initWithTitle : (NSString *)itemDict[@"Title"]
                                               image : [self loadItemImage : itemDict] items : subMenu];
            [items addObject : newGroup];

         } else {
            MenuItemStaticInfo * const newItem = [[MenuItemStaticInfo alloc] initWithDictionary:itemDict];
            [items addObject : newItem];
         }
      }
      
      [self addMenuGroup : @"About CERN" withImage : [self loadItemImage : desc] forItems : items];
      [self setStateForGroup : menuItems.count - 1 from : desc];
   }
   
   return YES;
}

//________________________________________________________________________________________
- (BOOL) loadSeparator : (NSDictionary *) desc
{
   assert(desc != nil && "loadSeparator:, parameter 'desc' is nil");
   
   id objBase = desc[@"Category name"];
   assert(objBase != nil && [objBase isKindOfClass : [NSString class]] &&
          "loadSeparator:, 'Category name' either not found or has a wrong type");
   
   if ([(NSString *)objBase isEqualToString : @"Separator"]) {
      MenuSeparator * const separator = [[MenuSeparator alloc] init];
      [separator addMenuItemViewInto : scrollView controller : self];
      [menuItems addObject : separator];      
      return YES;
   }
   
   return NO;
}

//________________________________________________________________________________________
- (void) loadMenuContents
{
   menuItems = [[NSMutableArray alloc] init];

   //Read menu contents from the 'MENU.plist'.
   //Create menu items and corresponding views.
   NSString * const path = [[NSBundle mainBundle] pathForResource : @"MENU" ofType : @"plist"];
   NSDictionary * const plistDict = [NSDictionary dictionaryWithContentsOfFile : path];
   assert(plistDict != nil && "loadMenuContents:, no dictionary or MENU.plist found");

   id objBase = plistDict[@"Menu Contents"];
   assert(objBase != nil && "loadMenuContents:, object for the key 'Menu Contents was not found'");
   assert([objBase isKindOfClass : [NSArray class]] &&
          "loadMenuContents, menu contents must be of a NSArray type");
          
   NSArray * const menuContents = (NSArray *)objBase;
   assert(menuContents.count != 0 && "loadMenuContents, menu arrays is empty");
   
   for (id entryBase in menuContents) {
      assert([entryBase isKindOfClass:[NSDictionary class]] &&
             "loadMenuContents, NSDictionary expected for menu item(s)");
      
      if ([self loadNewsSection : (NSDictionary *)entryBase])
         continue;
      
      if ([self loadLIVESection : (NSDictionary *)entryBase])
         continue;
      
      if ([self loadStaticInfo : (NSDictionary *)entryBase])
         continue;
      
      if ([self loadSeparator : (NSDictionary *)entryBase])
         continue;

      //Latest photos;
      //Latest videos;
      //Jobs;
      //Webcasts.
   }
}

//________________________________________________________________________________________
- (void) layoutMenuResetOffset : (BOOL) resetOffset resetContentSize : (BOOL) resetContentSize
{
   CGRect currentFrame = {0.f, 0.f, scrollView.frame.size.width};
   CGFloat totalHeight = 0.f;
   
   for (NSObject<MenuItemProtocol> *item in menuItems) {
      const CGFloat add = [item layoutItemViewWithHint : currentFrame];
      totalHeight += add;
      currentFrame.origin.y += add;
   }

   if (resetOffset)
      scrollView.contentOffset = CGPoint();

   if (resetContentSize)
      scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, totalHeight);
}

#pragma mark - View lifecycle's management.

//________________________________________________________________________________________
- (void) awakeFromNib
{
   inAnimation = NO;
   newOpen = nil;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   
   [self.slidingViewController setAnchorRightRevealAmount : 280.f];
   self.slidingViewController.underLeftWidthLayout = ECFullWidth;
   
   //We additionally setup a table view here.
   using CernAPP::menuBackgroundColor;
   scrollView.backgroundColor = [UIColor colorWithRed : menuBackgroundColor[0] green : menuBackgroundColor[1]
                                         blue : menuBackgroundColor[2] alpha : 1.f];
   scrollView.showsHorizontalScrollIndicator = NO;
   scrollView.showsVerticalScrollIndicator = NO;
   
   selectedItemView = nil;
   [self loadMenuContents];
}

//________________________________________________________________________________________
- (void) viewDidLayoutSubviews
{
   [self layoutMenuResetOffset : YES resetContentSize : YES];
}

#pragma mark - Menu animations.

//________________________________________________________________________________________
- (void) itemViewWasSelected : (MenuItemView *) view
{
   assert(view != nil && "itemViewWasSelected:, parameter 'view' is nil");

   if (selectedItemView) {
      selectedItemView.isSelected = NO;
      [selectedItemView setNeedsDisplay];
   }
   
   selectedItemView = view;
   selectedItemView.isSelected = YES;
   [selectedItemView setNeedsDisplay];
}

//________________________________________________________________________________________
- (void) groupViewWasTapped : (MenuItemsGroupView *) view
{
   assert(view != nil && "groupViewWasTapped:, parameter 'view' is nil");

   if (inAnimation)
      return;
   
   MenuItemsGroup * const group = view.menuItemsGroup;
   newOpen = nil;

   if (!group.parentGroup) {
      //When we expand/collapse a sub-menu, we have to also adjust our
      //scrollview - scroll to this sub-menu (if it's opened) or another
      //opened sub-menu (above or below the selected sub-menu).
      for (NSUInteger i = 0, e = menuItems.count; i < e; ++i) {
         NSObject<MenuItemProtocol> * const itemBase = (NSObject<MenuItemProtocol> *)menuItems[i];
         if (![itemBase isKindOfClass : [MenuItemsGroup class]])
            continue;//We scroll only to open sub-menus.

         MenuItemsGroup * const currGroup = (MenuItemsGroup *)itemBase;
         if (currGroup != group) {
            if (!currGroup.collapsed)
               newOpen = currGroup;//Index of open sub-menu above our selected sub-menu.
         } else {
            if (group.collapsed)//Group is collapsed, now will become open.
               newOpen = group;//It's our sub-menu who's open.
            else {
               //Group was open, now will collapse.
               //Do we have any open sub-menus at all?
               if (!newOpen) {//Nothing was open above our sub-menu. Search for the first open below.
                  for (NSUInteger j = i + 1; j < e; ++j) {
                     if ([menuItems[j] isKindOfClass : [MenuItemsGroup class]]) {
                        if (!((MenuItemsGroup *)menuItems[j]).collapsed) {
                           newOpen = (MenuItemsGroup *)menuItems[j];
                           break;
                        }
                     }
                  }
               }
            }
            
            break;
         }
      }
   } else
      newOpen = group.parentGroup;//We have to focus on group's parent group.
   
   [self animateMenuForItem : group];
}

//________________________________________________________________________________________
- (void) setAlphaAndVisibilityForGroup : (MenuItemsGroup *) group
{
   //During animation, if view will appear it's alpha changes from 0.f to 1.f,
   //and if it's going to disappear - from 1.f to 0.f.
   //Also, I have to animate small triangle, which
   //shows group's state (expanded/collapsed).
   
   assert(group != nil && "setAlphaAndVisibilityForGroup:, parameter 'group' is nil");
   
   if (group.containerView.hidden) {
      if (!group.collapsed) {
         group.containerView.hidden = NO;
         group.groupView.alpha = 1.f;
         //Triangle animation.
         group.titleView.discloseImageView.transform = CGAffineTransformMakeRotation(0.f);//rotate the triangle.
      }
   } else if (group.collapsed) {
      group.groupView.alpha = 0.f;
      //Triangle animation.
      group.titleView.discloseImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);//rotate the triangle.
   }
}

//________________________________________________________________________________________
- (void) adjustMenu
{
   assert(inAnimation == YES && "adjustMenu, can be called only during an animation");

   //Content view size.
   CGFloat totalHeight = 0.f;

   for (NSObject<MenuItemProtocol> *menuItem in menuItems) {
      if ([menuItem isKindOfClass:[MenuItemsGroup class]]) {
         if (((MenuItemsGroup *)menuItem).collapsed) {
            totalHeight += CernAPP::groupMenuItemHeight;
            continue;
         }
      }

      totalHeight += [menuItem requiredHeight];
   }

   CGRect frameToShow = CGRectMake(0.f, 0.f, scrollView.frame.size.width, CernAPP::groupMenuItemHeight);

   if (newOpen != nil) {
      frameToShow = newOpen.containerView.frame;
      if (!newOpen.parentGroup) {
         frameToShow.origin.y -= CernAPP::groupMenuItemHeight;
         frameToShow.size.height += CernAPP::groupMenuItemHeight;
      } else {
         frameToShow.origin.y -= CernAPP::childMenuItemHeight;
         frameToShow.size.height += CernAPP::childMenuItemHeight;
      }
   }
   
   [UIView animateWithDuration : 0.15f animations : ^ {
      scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, totalHeight);
   } completion : ^ (BOOL) {
      [scrollView scrollRectToVisible : frameToShow animated : YES];
   }];

   inAnimation = NO;
}

//________________________________________________________________________________________
- (void) hideGroupViews
{
   for (NSObject<MenuItemProtocol> *itemBase in menuItems) {
      if ([itemBase isKindOfClass : [MenuItemsGroup class]]) {
         MenuItemsGroup * const group = (MenuItemsGroup *)itemBase;
         for (NSUInteger i = 0, e = group.nItems; i < e; ++i) {
            NSObject<MenuItemProtocol> * const nested = [group item : i];
            if ([nested isKindOfClass : [MenuItemsGroup class]]) {
               MenuItemsGroup * const nestedGroup = (MenuItemsGroup *)nested;
               nestedGroup.containerView.hidden = nestedGroup.collapsed;
            }
         }

         group.containerView.hidden = group.collapsed;
      }
   }
}

//________________________________________________________________________________________
- (void) animateMenuForItem : (MenuItemsGroup *) groupItem
{
   //'groupItem' has just changed it's state.

   assert(groupItem != nil && "animateMenuForItem:, parameter 'groupItem' is nil");
   assert(inAnimation == NO && "animateMenu, called during active animation");

   inAnimation = YES;

   [self layoutMenuResetOffset : NO resetContentSize : YES];//Set menu items before the animation.

   //Now, change the state of menu item.
   groupItem.collapsed = !groupItem.collapsed;
   
   [UIView animateWithDuration : 0.25f animations : ^ {
      [self layoutMenuResetOffset : NO resetContentSize : NO];//Layout menu again, but with different positions for groupItem (and it's children).
      [self setAlphaAndVisibilityForGroup : groupItem];
   } completion : ^ (BOOL) {
      [self hideGroupViews];
      [self adjustMenu];
   }];
}

@end
