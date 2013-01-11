//
//  StaticInfoTableViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/10/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <cassert>

#import "StaticInfoScrollViewController.h"
#import "StaticInfoTableViewController.h"
#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"

@implementation StaticInfoTableViewController {
   NSMutableArray *views;
   
   __weak MenuTableItemView *selected;
}

@synthesize staticInfo;

//________________________________________________________________________________________
- (void) dealloc
{
   [views removeAllObjects];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];

   assert(staticInfo && staticInfo.count > 0 && "viewDidLoad, staticInfo is either nil or is empty");
   scrollView.backgroundColor = [UIColor colorWithRed : 0.827f green : 0.853f blue : 0.862f alpha : 1.f];
   
   views = [[NSMutableArray alloc] init];
   
   NSUInteger row = 0;
   for (id obj in staticInfo) {
      MenuTableItemView * const newView = [[MenuTableItemView alloc] initWithFrame : CGRectMake(0.f, 0.f, 100.f, 100.f)];
      [scrollView addSubview : newView];
      [views addObject : newView];
      
      UITapGestureRecognizer * const tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget : self action : @selector(cellTapped:)];
      [tapRecognizer setNumberOfTapsRequired : 1];
      [newView addGestureRecognizer : tapRecognizer];
      
      newView.rowIndex = row++;
   }
}

//________________________________________________________________________________________
- (void) viewDidLayoutSubviews
{
   using CernAPP::CellAppearance;

   const CGRect frame = scrollView.frame;
   
   CGFloat totalHeight = 0.f;
   const CGFloat addY = 10.f;
   CGFloat currentY = addY;
   
   NSUInteger i = 0;
   for (id obj in staticInfo) {
      MenuTableItemView * const view = views[i++];
      assert([obj isKindOfClass : [NSDictionary class]] &&
             "viewDidLayoutSubviews, item in a static info must be NSDictionary");
      NSDictionary * const item = (NSDictionary *)obj;
      
      if (!view.imageView.image) {
         assert([[item objectForKey : @"Thumbnail image"] isKindOfClass : [NSString class]] &&
                "viewDidLayoutSubviews, 'Thumbnail image' is not found or has a wrong type");
         
         UIImage * const thumbnail = [UIImage imageNamed:(NSString *)item[@"Thumbnail image"]];
         view.imageView.image = thumbnail;
         
         const CGSize imageSize = thumbnail.size;
         
         if (imageSize.width >= 1.5f * imageSize.height)
            view.appearance = CellAppearance::withWideImage;
         else
            view.appearance = CellAppearance::withSquareImage;
      }
      
      CernAPP::SetCellLayout(view, frame, currentY);
      CernAPP::SetCellLayer(view);
      
      view.textLabel.text = (NSString *)item[@"Title"];
      
      currentY += view.frame.size.height + addY;
      totalHeight = currentY;
   }
   
   [scrollView setContentSize : CGSizeMake(frame.size.width, totalHeight)];
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark - Cell interactions/animations

//________________________________________________________________________________________
- (void) selectRow : (NSUInteger) row
{
   assert(row < staticInfo.count && "selectRow:, parameter 'row' is out of bounds");
   //StaticInfoScrollViewControllerNoRootID
  
   assert([staticInfo[row] isKindOfClass : [NSDictionary class]] &&
          "selectRow:, info must have NSDictionary type");
   
   NSDictionary * const info = (NSDictionary *)staticInfo[row];
   
   assert([info[@"Title"] isKindOfClass : [NSString class]] &&
          "selectRow:, 'Title' not found or has a wrong type");
   assert([info[@"Items"] isKindOfClass : [NSArray class]] &&
          "selectRow:, 'Items' not found or has a wrong type");
   
   
   StaticInfoScrollViewController * const controller = [self.storyboard instantiateViewControllerWithIdentifier:CernAPP::StaticInfoScrollViewControllerNoRootID];
   controller.dataSource = (NSArray *)info[@"Items"];
   controller.navigationItem.title = (NSString *)info[@"Title"];
   [self.navigationController pushViewController : controller animated : YES];
   
   CernAPP::HiglightCell(selected, false);
   selected = nil;
}

//________________________________________________________________________________________
- (void) cellTapped : (UITapGestureRecognizer *) tapRecognizer
{
   assert(tapRecognizer != nil && "cellTapped:, parameter 'tapRecognizer' is nil");
   assert([tapRecognizer.view isKindOfClass : [MenuTableItemView class]] &&
          "cellTapped:, tapRecognizer.view must be MenuTableItemView");
   
   if (selected && selected != tapRecognizer.view)
      CernAPP::HiglightCell(selected, false);

   selected = (MenuTableItemView *)tapRecognizer.view;
   
   [UIView animateWithDuration : 0.2 animations : ^ {
      CernAPP::HiglightCell(selected, true);
   } completion : ^ (BOOL) {
      [self selectRow : selected.rowIndex];
   }];
}

#pragma mark - Sliding menu.

//________________________________________________________________________________________
- (IBAction) revealMenu : (id) sender
{
#pragma unused(sender)
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
