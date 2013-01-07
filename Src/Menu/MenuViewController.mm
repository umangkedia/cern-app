//This code is based on a code sample by Michael Enriquez (EdgeCase).
//Code was further developed/modified (and probably broken) by Timur Pocheptsov
//for CERN.app - to load our own menu we need.

#import <cassert>

#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"
#import "MenuViewController.h"
#import "MenuItems.h"

using CernAPP::ItemStyle;

@implementation MenuViewController {
   NSMutableArray *menuItems;
}

@synthesize tableView;

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
         //First, add a section title.
         [menuItems addObject : [[GroupTitle alloc] initWithTitle : sectionName]];
         
         for (id info in feeds) {
            assert([info isKindOfClass : [NSDictionary class]] &&
                   "loadNewsSection, feed info must be a dictionary");
            NSDictionary * const feedInfo = (NSDictionary *)info;
            FeedProvider * const provider = [[FeedProvider alloc] initWith : feedInfo];
            //Now, after we created a provider, we can add menu item.
            [menuItems addObject : [[MenuItem alloc] initWithContentProvider : provider]];
         }
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
      GroupTitle *newTitle = [[GroupTitle alloc] initWithTitle : @"LIVE"];
      [menuItems addObject : newTitle];
   
      //This is just an array of strings.
      for (id expBase in experimentNames) {
         assert([expBase isKindOfClass : [NSString class]] &&
                "loadLIVESection:, experiment's name must have a NSString type");
         //
         [menuItems addObject : [[MenuItemLIVE alloc] initWithExperiment : (NSString *)expBase]];
         //
      }
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
- (void) awakeFromNib
{
   //Here we work with our content providers.
   [self loadMenuContents];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   [self.slidingViewController setAnchorRightRevealAmount : 280.f];
   self.slidingViewController.underLeftWidthLayout = ECFullWidth;
   
   //We additionally setup a table view here.
   tableView.backgroundColor = [UIColor colorWithRed : 0.5f green : 0.5f blue : 0.5f alpha : 1.f];
   tableView.separatorColor = [UIColor colorWithRed : 0.5f green : 0.5f blue : 0.5f alpha : 1.f];
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) aTableView numberOfRowsInSection : (NSInteger) sectionIndex
{
#pragma unused(aTableView, sectionIndex)

   return menuItems.count;
}

//________________________________________________________________________________________
- (void) tableView : (UITableView *) aTableView willDisplayCell : (UITableViewCell *) cell
         forRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(aTableView)

   assert(indexPath != nil &&
          "tableView:willDisplayCell:forRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < menuItems.count &&
          "tableView:willDisplayCell:forRowAtIndexPath:, index is out of bounds");

   NSObject<MenuItemProtocol> * const item = (NSObject<MenuItemProtocol> *)menuItems[row];
   
   if (item.itemStyle == ItemStyle::groupTitle) {
      cell.backgroundColor = [UIColor colorWithPatternImage : [UIImage imageNamed : @"navbarback.png"]];
      cell.textLabel.textColor = [UIColor whiteColor];
      cell.textLabel.font = [UIFont fontWithName : @"PT Sans" size : 18.f];
   } else {
      [cell setBackgroundColor : [UIColor colorWithRed : 0.4f green : 0.4f blue : 0.4f alpha : 1.f]];
      cell.textLabel.textColor = [UIColor blackColor];
      cell.textLabel.font = [UIFont fontWithName : @"PT Sans" size : 14.f];
   }
}

//________________________________________________________________________________________
- (NSIndexPath *) tableView : (UITableView *) aTableView willSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(aTableView)

   assert(indexPath != nil &&
          "tableView:willSelectRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < menuItems.count &&
          "tableView:willSelectRowAtIndexPath:, index is out of bounds");

   NSObject<MenuItemProtocol> * const item = (NSObject<MenuItemProtocol> *)menuItems[row];
   if (item.isSelectable)
      return indexPath;
   
   return nil;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) aTableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(aTableView)

   assert(indexPath != nil && "tableView:cellForRowAtIndexPath:, parameter 'indexPath' is nil");
   
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < menuItems.count &&
          "tableView:cellForRowAtIndexPath:, index is out of bounds");

   NSString * const cellIdentifier = @"MenuItemCell";
   UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier : cellIdentifier];
   if (!cell)
      cell = [[UITableViewCell alloc] initWithStyle : UITableViewCellStyleSubtitle reuseIdentifier : cellIdentifier];

   NSObject<MenuItemProtocol> * const item = (NSObject<MenuItemProtocol> *)menuItems[row];
   cell.textLabel.text = item.itemText;

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) aTableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(aTableView)

   assert(indexPath != nil && "tableView:heightForRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < menuItems.count &&
          "tableView:heightForRowAtIndexPath:, index is out of bounds");
   
   NSObject<MenuItemProtocol> * const item = (NSObject<MenuItemProtocol> *)menuItems[row];
   if (item.itemStyle == ItemStyle::groupTitle)
      return 44.f;

   return 30.f;
}

//________________________________________________________________________________________
- (void) tableView : (UITableView *) aTableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(aTableView)

   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath:, parameter 'indexPath' is nil");
   
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < menuItems.count &&
          "tableView:didSelectRowAtIndexPath:, index is out of bounds");

   NSObject<MenuItemProtocol> * const selectedItem = (NSObject<MenuItemProtocol> *)menuItems[row];
   [selectedItem itemPressedIn : self];
}

@end
