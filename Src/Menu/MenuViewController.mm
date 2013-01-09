#import <cassert>
#import <limits>
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
   
   //For the moment, the number of 'top-level' (non-nested) menu items is limited by number of bits in unsigned :))
   //Yeah, it's lame, I'll use a bitset later :)
   unsigned menuState;
   
   BOOL inAnimation;
   int newOpen;
}

//________________________________________________________________________________________
- (UIImage *) loadItemImage : (NSDictionary *) desc
{
   assert(desc != nil && "loadItemImage:, parameter 'desc' is nil");
   
   if (id objBase = [desc objectForKey : @"Image name"]) {
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
   
   assert([[desc objectForKey : @"Expanded"] isKindOfClass : [NSNumber class]] &&
          "setStateForGroup:from:, 'Expanded' is not found or has a wrong type");
   
   const NSInteger val = [(NSNumber *)[desc objectForKey : @"Expanded"] integerValue];
   assert(!val || val == 1 && "setStateForGroup:from:, 'Expanded' must have a value either 0 or 1");
   
   if (!val) {
      group.containerView.hidden = YES;
      group.titleView.discloseImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
   } else
      menuState |= 1 << groupIndex;
}


//TODO: the following 3 functions do almost exactly the same work, so it's not bad to refactor them
//into a generic function?

//________________________________________________________________________________________
- (BOOL) loadNewsSection : (NSDictionary *) desc
{
   assert(scrollView != nil && "loadNewSection:, scrollView is not loaded yet!");
   assert(desc != nil && "loadNewsSection:, parameter 'desc' is nil");
   
   id objBase = [desc objectForKey : @"Category name"];
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadNewsSection:, either 'Category Name' not found, or it's not a NSString");
   
   NSString * const catName = (NSString *)objBase;
   if (![catName isEqualToString : @"News"])
      return NO;
   
   //Find a section name, it's a required property.
   objBase = [desc objectForKey : @"Name"];
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadNewsSection:, either 'Name' not found, or it's not a NSString");
   
   NSString * const sectionName = (NSString *)objBase;
   
   //Now, we need an array of either feeds or tweets.
   objBase = [desc objectForKey : @"Feeds"];
   if (objBase) {
      assert([objBase isKindOfClass:[NSArray class]] &&
             "loadNewsSection:, 'Feeds' must have a NSArray type");
      NSArray * const feeds = (NSArray *)objBase;
      if (feeds.count) {
         assert(menuItems.count + 1 < 32 && "loadNewsSection:, menu can not have more than 32 items");
         
         UIView * const containerView = [[UIView alloc] initWithFrame : CGRect()];
         containerView.clipsToBounds = YES;
         UIView * const groupView = [[UIView alloc] initWithFrame : CGRect()];
         [containerView addSubview : groupView];
         [scrollView addSubview : containerView];

         NSMutableArray * const items = [[NSMutableArray alloc] init];
         for (id info in feeds) {
            assert([info isKindOfClass : [NSDictionary class]] &&
                   "loadNewsSection, feed info must be a dictionary");
            NSDictionary * const feedInfo = (NSDictionary *)info;
            FeedProvider * const provider = [[FeedProvider alloc] initWith : feedInfo];

            MenuItem * const newItem = [[MenuItem alloc] initWithContentProvider : provider];
            [items addObject : newItem];
            
            MenuItemView * const itemView = [[MenuItemView alloc] initWithFrame:CGRect() item : newItem
                                             style : ItemStyle::child controller : self];
            newItem.itemView = itemView;
            [groupView addSubview : itemView];
         }


         MenuItemsGroup * const group = [[MenuItemsGroup alloc] initWithTitle : sectionName
                                         image : [self loadItemImage : desc] items : items index : menuItems.count];
         MenuItemsGroupView * const menuGroupView = [[MenuItemsGroupView alloc] initWithFrame:CGRect()
                                                     item : group controller : self];
         [scrollView addSubview : menuGroupView];
         
         group.titleView = menuGroupView;
         group.containerView = containerView;
         group.groupView = groupView;
         
         [menuItems addObject : group];
         [self setStateForGroup : menuItems.count - 1 from : desc];
      }
   }

   return YES;
}

//________________________________________________________________________________________
- (BOOL) loadLIVESection : (NSDictionary *) desc
{
   assert(desc != nil && "loadLIVESection:, parameter 'desc' is nil");
   
   id objBase = [desc objectForKey : @"Category name"];
   assert(objBase != nil && "loadLIVESection:, 'Category Name' not found");
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadLIVESection:, 'Category Name' must have a NSString type");
   
   NSString * const catName = (NSString *)objBase;
   if (![catName isEqualToString : @"LIVE"])
      return NO;

   objBase = [desc objectForKey : @"Experiments"];
   assert(objBase != nil && "loadLIVESection:, 'Experiments' not found");
   assert([objBase isKindOfClass:[NSArray class]] &&
          "loadLIVESection:, 'Experiments' must have a NSArray type");
   
   NSArray * const experimentNames = (NSArray *)objBase;
   
   if (experimentNames.count) {
      //
      assert(menuItems.count + 1 < 32 && "loadLIVESection:, menu cannot have more than 32 items");
      //
      UIView * const containerView = [[UIView alloc] initWithFrame : CGRect()];
      containerView.clipsToBounds = YES;
      UIView * const groupView = [[UIView alloc] initWithFrame : CGRect()];
      [containerView addSubview : groupView];
      [scrollView addSubview : containerView];
      
      NSMutableArray * const items = [[NSMutableArray alloc] init];
      for (id expBase in experimentNames) {
         //This is just an array of strings.
         assert([expBase isKindOfClass : [NSString class]] &&
                "loadLIVESection:, experiment's name must have a NSString type");
         
         MenuItemLIVE * liveItem = [[MenuItemLIVE alloc] initWithExperiment : (NSString *)expBase];
         [items addObject : liveItem];
            
         MenuItemView * const itemView = [[MenuItemView alloc] initWithFrame:CGRect() item : liveItem
                                          style : ItemStyle::child controller : self];
         liveItem.itemView = itemView;
         [groupView addSubview : itemView];
      }


      MenuItemsGroup * const group = [[MenuItemsGroup alloc] initWithTitle : @"LIVE"
                                      image : [self loadItemImage : desc] items : items index : menuItems.count];
      MenuItemsGroupView * const menuGroupView = [[MenuItemsGroupView alloc] initWithFrame : CGRect()
                                                  item : group controller : self];
      [scrollView addSubview : menuGroupView];
         
      group.titleView = menuGroupView;
      group.containerView = containerView;
      group.groupView = groupView;

      [menuItems addObject : group];
      [self setStateForGroup : menuItems.count - 1 from : desc];
   }

   return YES;
}

//________________________________________________________________________________________
- (BOOL) loadStaticInfo : (NSDictionary *) desc
{
   assert(desc != nil && "loadStaticInfo, parameter 'desc' is nil");
   
   id objBase = [desc objectForKey : @"Category name"];
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadStaticInfo:, 'Category name' either not found or has a wrong type");
   
   if (![(NSString *)objBase isEqualToString : @"StaticInfo"])
      return NO;

   
   objBase = [desc objectForKey : @"Name"];
   assert([objBase isKindOfClass : [NSString class]] &&
          "loadStaticInfo:, 'Name' either not found or has a wrong type");
   
   NSString * const sectionName = (NSString *)objBase;
   
   objBase = [desc objectForKey : @"Entries"];
   //It must be an NSArray ...
   assert([objBase isKindOfClass : [NSArray class]] &&
          "loadStaticInfo:, 'Entries' either not found or has a wrong type");
   
   NSArray * const staticInfoEntries = (NSArray *)objBase;
   
   if (staticInfoEntries.count) {
      assert(menuItems.count + 1 < 32 && "loadStaticInfo:, menu cannot have more than 32 items");
      //
      UIView * const containerView = [[UIView alloc] initWithFrame : CGRect()];
      containerView.clipsToBounds = YES;
      UIView * const groupView = [[UIView alloc] initWithFrame : CGRect()];
      [containerView addSubview : groupView];
      [scrollView addSubview : containerView];
      
      NSMutableArray * const items = [[NSMutableArray alloc] init];
      for (objBase in staticInfoEntries) {
         //... of NSDictionary object.
         assert([objBase isKindOfClass : [NSDictionary class]] &&
                "loadStaticInfo:, NSDictionary expected");

         objBase = [(NSDictionary *)objBase objectForKey : @"Name"];
         assert([objBase isKindOfClass : [NSString class]] &&
                "loadStaticInfo:, 'Name' either not found or has a wrong string");
         NSObject<MenuItemProtocol> * const newItem = [[MenuItemStaticInfo alloc] initWithKey: (NSString *)objBase];
         
         MenuItemView * const itemView = [[MenuItemView alloc] initWithFrame:CGRect() item : newItem
                                          style : ItemStyle::child controller : self];
         newItem.itemView = itemView;
         [groupView addSubview : itemView];
         
         [items addObject : newItem];
      }
      
      //Now, lets create a group item.
      MenuItemsGroup * const group = [[MenuItemsGroup alloc] initWithTitle : sectionName
                                      image : [self loadItemImage : desc] items : items index : menuItems.count];
      MenuItemsGroupView * const menuGroupView = [[MenuItemsGroupView alloc] initWithFrame : CGRect()
                                                  item : group controller : self];
      [scrollView addSubview : menuGroupView];
         
      group.titleView = menuGroupView;
      group.containerView = containerView;
      group.groupView = groupView;

      [menuItems addObject : group];
      [self setStateForGroup : menuItems.count - 1 from : desc];
   }
   
   
   return YES;
}

//________________________________________________________________________________________
- (BOOL) loadSeparator : (NSDictionary *) desc
{
   assert(desc != nil && "loadSeparator:, parameter 'desc' is nil");
   
   id objBase = [desc objectForKey : @"Category name"];
   assert(objBase != nil && [objBase isKindOfClass : [NSString class]] &&
          "loadSeparator:, 'Category name' either not found or has a wrong type");
   
   if ([(NSString *)objBase isEqualToString : @"Separator"]) {
      assert(menuItems.count + 1 < 32 && "loadSeparator:, menu can not have more than 32 items");
      MenuSeparator * const separator = [[MenuSeparator alloc] init];
      MenuItemView * const separatorView = [[MenuItemView alloc] initWithFrame:CGRect() item : nil style : ItemStyle::separator controller : self];
      separator.itemView = separatorView;
      [scrollView addSubview : separatorView];
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

   id objBase = [plistDict objectForKey:@"Menu Contents"];
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

      //Static info (about CERN);
      //Latest photos;
      //Latest videos;
      //Jobs;
      //Webcasts.
   }
}

//________________________________________________________________________________________
- (CGFloat) layoutMenuGroup : (NSUInteger) groupIndex frameHint : (CGRect) hint
{
   assert(groupIndex < menuItems.count &&
          "layoutMenuGroup:frameHint:, parameter 'groupIndex' is out of bounds");

   NSObject<MenuItemProtocol> * const itemBase = menuItems[groupIndex];
   assert([itemBase isKindOfClass : [MenuItemsGroup class]] &&
          "layoutMenuGroup:frameHint:, item to layout is not a menu group");

   MenuItemsGroup * group = (MenuItemsGroup *)itemBase;
   CGFloat totalHeight = 0.f;
   //
   hint.size.height = CernAPP::groupMenuItemHeight;
   group.titleView.frame = hint;
   [group.titleView layoutText];
   
   totalHeight += CernAPP::groupMenuItemHeight;
   hint.origin.y += CernAPP::groupMenuItemHeight;
         //
   CGRect containerFrame = hint;
   containerFrame.size.height = group.nItems * CernAPP::childMenuItemHeight;
   group.containerView.frame = containerFrame;
   containerFrame.origin = CGPoint();
   group.groupView.frame = containerFrame;

   totalHeight += containerFrame.size.height;         
         
   CGRect childFrame(hint);
   childFrame.origin.y = 0.f;
   
   for (NSUInteger i = 0, e = group.nItems; i < e; ++i) {
      //Let's place children views.
      childFrame.size.height = CernAPP::childMenuItemHeight;
            
      NSObject<MenuItemProtocol> * const childItem = [group item : i];
            
      assert([childItem respondsToSelector : @selector(itemView)] &&
             "layoutMenu, child item does not have the 'itemView' selector");
            
      MenuItemView * const childView = childItem.itemView;
      childView.frame = childFrame;
      [childView layoutText];

      childFrame.origin.y += CernAPP::childMenuItemHeight;
   }

   if ((1 << groupIndex) & menuState) {
      //Group is expanded now.
      group.titleView.discloseImageView.transform = CGAffineTransformMakeRotation(0.f);
   } else {
      //Group is collapsed.
      group.groupView.alpha = 0.f;
      CGRect newFrame = group.groupView.frame;
      newFrame.origin.y -= newFrame.size.height;
      group.groupView.frame = newFrame;
      totalHeight = CernAPP::groupMenuItemHeight;
   }
   
   return totalHeight;
}

//________________________________________________________________________________________
- (void) layoutMenu
{
   CGRect currentFrame = {0.f, 0.f, scrollView.frame.size.width};
   CGFloat totalHeight = 0.f;
   
   for (NSUInteger i = 0, e = menuItems.count; i < e; ++i) {
      NSObject<MenuItemProtocol> * const item = menuItems[i];
      if ([item isKindOfClass : [MenuItemsGroup class]]) {
         const CGFloat addY = [self layoutMenuGroup : i frameHint : currentFrame];
         currentFrame.origin.y += addY;
         totalHeight += addY;   
      } else {
         //That's a single item.
         assert([item respondsToSelector:@selector(itemView)] &&
                "layoutMenu, single menu item must respond to 'itemView' selector");
         
         MenuItemView * const view = item.itemView;
         currentFrame.size.height = CernAPP::childMenuItemHeight;
         view.frame = currentFrame;
         currentFrame.origin.y += CernAPP::childMenuItemHeight;
         totalHeight += CernAPP::childMenuItemHeight;
      }
   }
   
   scrollView.contentOffset = CGPoint();
   scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, totalHeight);
}

#pragma mark - View lifecycle's management.

//________________________________________________________________________________________
- (void) awakeFromNib
{
   inAnimation = NO;
   newOpen = -1;
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

   static_assert(std::numeric_limits<unsigned>::digits >= 32, "bad number of bits in unsigned");   
   [self loadMenuContents];
}

//________________________________________________________________________________________
- (void) viewDidLayoutSubviews
{
   [self layoutMenu];
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
   group.collapsed = !group.collapsed;
   newOpen = -1;

   //When we expand/collapse a sub-menu, we have to also adjust our
   //scrollview - scroll to this sub-menu (if it's opened) or another
   //opened sub-menu (above or below the selected sub-menu).
   for (NSUInteger i = 0, e = menuItems.count; i < e; ++i) {
      NSObject<MenuItemProtocol> * const itemBase = (NSObject<MenuItemProtocol> *)menuItems[i];
      if (![itemBase isKindOfClass : [MenuItemsGroup class]])
         continue;//We scroll only to open sub-menus.

      MenuItemsGroup * const currGroup = (MenuItemsGroup *)itemBase;
      if (currGroup != group) {
         if (menuState & (1 << i))
            newOpen = i;//Index of open sub-menu above our selected sub-menu.
      } else {
         menuState ^= (1 << i);//we change a state of our sub-menu.
         if (menuState & (1 << i))
            newOpen = i;//It's our sub-menu who's open.
         else if (menuState) {//Do we have any open sub-menus at all?
            if (newOpen == -1) {//Nothing was open above our sub-menu. Search for the first open below.
               for (NSUInteger j = i + 1; j < e; ++j) {
                  if ([menuItems[j] isKindOfClass : [MenuItemsGroup class]]) {
                     if (menuState & (1 << j)) {
                        newOpen = j;
                        break;
                     }
                  }
               }
            }
         }
         
         [self animateMenu];
         break;
      }
   }
}

//________________________________________________________________________________________
- (void) presetViewsYs
{
   //These are coordinates before an animation started.
   CGRect currentFrame = scrollView.frame;

   for (NSUInteger i = 0, e = menuItems.count; i < e; ++i) {
      NSObject<MenuItemProtocol> * const itemBase = (NSObject<MenuItemProtocol> *)menuItems[i];
      
      if ([itemBase isKindOfClass : [MenuItemsGroup class]]) {
         //Set sub-menu title.
         MenuItemsGroup * const group = (MenuItemsGroup *)itemBase;
         currentFrame.origin.y += CernAPP::groupMenuItemHeight;
         
         if (group.containerView.hidden) {//This sub-menu is becoming visible now.
            if (menuState & (1 << i)) {
               CGRect frame = group.groupView.frame;
               frame.origin.y = currentFrame.origin.y;
               group.containerView.frame = frame;
               frame.origin.y = -frame.size.height;
               //Sub-menu will move into container from 'nowhere'.
               group.groupView.frame = frame;
               
               break;
            }
         } else
            currentFrame.origin.y += group.containerView.frame.size.height;
      } else if ([itemBase isKindOfClass : [MenuItem class]] || [itemBase isKindOfClass : [MenuSeparator class]]) {
         currentFrame.origin.y += CernAPP::childMenuItemHeight;
      } else {
         assert(0 && "presetViewsYs, implement me!!!");
      }
   }
}

//________________________________________________________________________________________
- (void) setViewsYs
{
   //These are menu items positions at the end of animation.
   [self layoutMenu];
}

//________________________________________________________________________________________
- (void) setViewsAlphaAndVisibility
{
   //During animation, if view will appear it's alpha changes from 0.f to 1.f,
   //and if it's going to disappear - from 1.f to 0.f.
   //Also, I have to animate small triangle, which
   //shows group's state (expanded/collapsed).

   for (NSUInteger i = 0, e = menuItems.count; i < e; ++i) {
      NSObject<MenuItemProtocol> * const itemBase = (NSObject<MenuItemProtocol> *)menuItems[i];
      if ([itemBase isKindOfClass : [MenuItemsGroup class]]) {
         MenuItemsGroup * const group = (MenuItemsGroup *)itemBase;
         const bool isVisible = menuState & (1 << i);
         if (group.containerView.hidden) {
            if (isVisible) {
               group.containerView.hidden = NO;
               group.groupView.alpha = 1.f;
               //Triangle animation.
               group.titleView.discloseImageView.transform = CGAffineTransformMakeRotation(0.f);//rotate the triangle.
            }
         } else if (!isVisible) {
            group.groupView.alpha = 0.f;
            //Triangle animation.
            group.titleView.discloseImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);//rotate the triangle.
         }
      }
   }
}

//________________________________________________________________________________________
- (void) adjustMenu
{
   assert(inAnimation == YES && "adjustMenu, can be called only during an animation");

   //TODO: Adjust a scrollview.
   CGFloat totalHeight = 0.f;
   
   for (NSUInteger i = 0, e = menuItems.count; i < e; ++i) {
      NSObject<MenuItemProtocol> * const itemBase = (NSObject<MenuItemProtocol> *)menuItems[i];
      if ([itemBase isKindOfClass : [MenuItemsGroup class]]) {
         MenuItemsGroup * const group = (MenuItemsGroup *)itemBase;
         totalHeight += group.titleView.frame.size.height;
         if (!group.containerView.hidden)
            totalHeight += group.containerView.frame.size.height;
      } else {
         assert([itemBase respondsToSelector : @selector(itemView)] &&
                "adjustMenu, non-group menu item must respong to 'itemView' selector");
         totalHeight += itemBase.itemView.frame.size.height;
      }
   }
   
   scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, totalHeight);

   CGRect frameToShow = CGRectMake(0.f, 0.f, scrollView.frame.size.width, CernAPP::groupMenuItemHeight);

   if (newOpen != -1) {
      assert(newOpen >= 0 && newOpen < menuItems.count && "adjustMenu, newOpen is out of bounds");
      NSObject<MenuItemProtocol> * const itemBase = (NSObject<MenuItemProtocol> *)menuItems[newOpen];
      assert([itemBase isKindOfClass : [MenuItemsGroup class]] &&
             "adjustMenu, newOpen must be a menu group");
      MenuItemsGroup * const group = (MenuItemsGroup *)itemBase;
      frameToShow = group.containerView.frame;
      frameToShow.origin.y -= CernAPP::groupMenuItemHeight;
      frameToShow.size.height += CernAPP::groupMenuItemHeight;
   }
   
   [scrollView scrollRectToVisible : frameToShow animated : YES];
   inAnimation = NO;
}

//________________________________________________________________________________________
- (void) hideGroupViews
{
   for (NSUInteger i = 0, e = menuItems.count; i < e; ++i) {
      NSObject<MenuItemProtocol> * const itemBase = (NSObject<MenuItemProtocol> *)menuItems[i];
      if ([itemBase isKindOfClass : [MenuItemsGroup class]]) {
         MenuItemsGroup * const group = (MenuItemsGroup *)itemBase;
         if (!(menuState & (1 << i)))
            group.containerView.hidden = YES;
      }
   }
}

//________________________________________________________________________________________
- (void) animateMenu
{
   assert(inAnimation == NO && "animateMenu, called during active animation");

   inAnimation = YES;

   [self presetViewsYs];
   
   [UIView beginAnimations : nil context : nil];
   [UIView setAnimationDuration : 0.25];
   [UIView setAnimationCurve : UIViewAnimationCurveEaseOut];
 
   [self setViewsYs];
   [self setViewsAlphaAndVisibility];

   [UIView commitAnimations];
 
   //Do not hide the views immediately, so user can see animation.
   [NSTimer scheduledTimerWithTimeInterval : 0.15 target : self selector : @selector(hideGroupViews) userInfo : nil repeats : NO];
   [NSTimer scheduledTimerWithTimeInterval : 0.3 target : self selector : @selector(adjustMenu) userInfo : nil repeats : NO];
}

@end
