//This code is based on a code sample by Michael Enriquez (EdgeCase).
//Code was further developed/modified (and probably broken) by Timur Pocheptsov
//for CERN.app - to load our own menu we need.

#import <cassert>

#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"
#import "MenuViewController.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"
#import "MenuItems.h"

using CernAPP::ItemStyle;

@implementation MenuViewController {
   NSMutableArray *menuItems;
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
                                         image : [self loadItemImage : desc] items : items];
         MenuItemsGroupView * const menuGroupView = [[MenuItemsGroupView alloc] initWithFrame:CGRect()
                                                     item : group controller : self];
         [scrollView addSubview : menuGroupView];
         
         group.titleView = menuGroupView;
         group.containerView = containerView;
         group.groupView = groupView;
         
         [menuItems addObject : group];
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
                                      image : [self loadItemImage : desc] items : items];
      MenuItemsGroupView * const menuGroupView = [[MenuItemsGroupView alloc] initWithFrame : CGRect()
                                                  item : group controller : self];
      [scrollView addSubview : menuGroupView];
         
      group.titleView = menuGroupView;
      group.containerView = containerView;
      group.groupView = groupView;
         
      [menuItems addObject : group];
   }

   return YES;
}

//________________________________________________________________________________________
- (void) loadMenuContents
{
   menuItems = [[NSMutableArray alloc] init];

   //Read menu contents from the 'MENU.plist'.
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
      
      //Static info (about CERN);
      //Latest photos;
      //Latest videos;
      //Jobs;
      //Webcasts.
   }
}

//________________________________________________________________________________________
- (void) layoutMenu
{
   CGRect currentFrame = {0.f, 0.f, scrollView.frame.size.width};
   CGFloat totalHeight = 0.f;
   
   for (NSObject<MenuItemProtocol> * item in menuItems) {
      if ([item isKindOfClass : [MenuItemsGroup class]]) {
         MenuItemsGroup * const group = (MenuItemsGroup *)item;
         //
         currentFrame.size.height = CernAPP::groupMenuItemHeight;
         group.titleView.frame = currentFrame;
         [group.titleView layoutText];
         totalHeight += CernAPP::groupMenuItemHeight;
         currentFrame.origin.y += CernAPP::groupMenuItemHeight;
         //
         CGRect containerFrame = currentFrame;
         containerFrame.size.height = group.nItems * CernAPP::childMenuItemHeight;
         group.containerView.frame = containerFrame;
         containerFrame.origin = CGPoint();
         group.groupView.frame = containerFrame;

         totalHeight += containerFrame.size.height;         
         
         CGRect childFrame = currentFrame;
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
         
         currentFrame.origin.y += containerFrame.size.height;
      }
   }
   
   scrollView.contentOffset = CGPoint();
   scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, totalHeight);
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   [self.slidingViewController setAnchorRightRevealAmount : 280.f];
   self.slidingViewController.underLeftWidthLayout = ECFullWidth;
   
   //We additionally setup a table view here.
   scrollView.backgroundColor = [UIColor colorWithRed : 0.5f green : 0.5f blue : 0.5f alpha : 1.f];
   scrollView.showsHorizontalScrollIndicator = NO;
   scrollView.showsVerticalScrollIndicator = NO;
   [self loadMenuContents];
}

//________________________________________________________________________________________
- (void) viewDidLayoutSubviews
{
   [self layoutMenu];
}

@end
