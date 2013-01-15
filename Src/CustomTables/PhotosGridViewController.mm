//
//  PhotosViewController.m
//  CERN App
//
//  Created by Eamon Ford on 6/27/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "PhotosGridViewController.h"
#import "CernMediaMARCParser.h"
#import "PhotoGridViewCell.h"
#import "ApplicationErrors.h"
#import "MBProgressHUD.h"
#import "DeviceCheck.h"
#import "AppDelegate.h"

@implementation PhotosGridViewController {
   MBProgressHUD *noConnectionHUD;
}

@synthesize photoDownloader;

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   if (self = [super initWithCoder:aDecoder]) {
      self.photoDownloader = [[PhotoDownloader alloc] init];
      self.photoDownloader.delegate = self;
   }

   return self;
}

//________________________________________________________________________________________
- (void) dealloc
{
   //
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];

   // When we call self.view this will reload the view after a didReceiveMemoryWarning.
   self.view.backgroundColor = [UIColor whiteColor];
   self.gridView.separatorStyle = AQGridViewCellSeparatorStyleSingleLine;
   self.gridView.resizesCellWidthToFit = YES;
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   [self refresh];
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];

   if (!self.photoDownloader.isDownloading) {
      self.photoDownloader.urls = nil;
      self.photoDownloader.thumbnails = nil;
   }
}

//________________________________________________________________________________________
- (void) refresh
{
   if (self.photoDownloader.urls.count == 0 && !self.photoDownloader.isDownloading) {
      [noConnectionHUD hide : YES];
      [MBProgressHUD showHUDAddedTo : self.view animated : YES];
      [self.photoDownloader parse];
   }
}

//________________________________________________________________________________________
- (void) reloadImages
{
   if (!self.photoDownloader.isDownloading) {
      if (!photoDownloader.hasConnection)
         CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
      else {
         self.photoDownloader.urls = nil;
         self.photoDownloader.thumbnails = nil;
         [self refresh];
      }
   }
}

#pragma mark - Interface methods

//________________________________________________________________________________________
- (void) reloadCellAtIndex : (NSNumber *) index
{
   [self.gridView reloadItemsAtIndices : [NSIndexSet indexSetWithIndex:[index intValue]] withAnimation:AQGridViewItemAnimationTop];
}

#pragma mark - PhotoDownloaderDelegate methods

//________________________________________________________________________________________
- (void) photoDownloaderDidFinish : (PhotoDownloader *) photoDownloader
{
   [MBProgressHUD hideHUDForView:self.view animated:YES];
   [self.gridView reloadData];
}

//________________________________________________________________________________________
- (void) photoDownloader : (PhotoDownloader *) photoDownloader didDownloadThumbnailForIndex : (int) index
{
   [self reloadCellAtIndex:[NSNumber numberWithInt:index]];
}

#pragma mark - AQGridView methods

//________________________________________________________________________________________
- (NSUInteger) numberOfItemsInGridView: (AQGridView *) gridView
{
   return self.photoDownloader.urls.count;
}

//________________________________________________________________________________________
- (AQGridViewCell *) gridView : (AQGridView *) gridView cellForItemAtIndex : (NSUInteger) index
{
   static NSString *photoCellIdentifier = @"photoCell";
   PhotoGridViewCell *cell = (PhotoGridViewCell *)[self.gridView dequeueReusableCellWithIdentifier:photoCellIdentifier];
   if (cell == nil) {
     cell = [[PhotoGridViewCell alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0) reuseIdentifier:photoCellIdentifier];
     cell.selectionStyle = AQGridViewCellSelectionStyleNone;
   }
   cell.imageView.image = [self.photoDownloader.thumbnails objectForKey:[NSNumber numberWithInt:index]];
   //cell.imageView.image = [UIImage imageNamed:@"cernLogo"];
   return cell;
}

//________________________________________________________________________________________
- (void) gridView : (AQGridView *) gridView didSelectItemAtIndex : (NSUInteger) index numFingersTouch : (NSUInteger)numFingers
{
   MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
   browser.displayActionButton = YES;
   [browser setInitialPageIndex:index];
   UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browser];
   navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
   [self presentViewController:navigationController animated:YES completion:nil];
}

//________________________________________________________________________________________
- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) aGridView
{
   return CGSizeMake(100.f, 100.f);
}

#pragma mark - MWPhotoBrowserDelegate methods

//________________________________________________________________________________________
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
   return self.photoDownloader.urls.count;
}

//________________________________________________________________________________________
- (MWPhoto *) photoBrowser : (MWPhotoBrowser *) photoBrowser photoAtIndex : (NSUInteger) index
{
   if (index < self.photoDownloader.urls.count) {
      NSString *photoSize;
      // Download a larger full-size image on iPad, or a smaller full-size image on iPhone
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
         photoSize = @"jpgA4";
      } else {
         photoSize = @"jpgA5";
      }

      NSURL *url = [[self.photoDownloader.urls objectAtIndex:index] objectForKey:photoSize];
      return [MWPhoto photoWithURL:url];
   }

   return nil;
}

//________________________________________________________________________________________
- (void) photoDownloader : (PhotoDownloader *) photoDownloader didFailWithError : (NSError *) error
{
   #pragma unused(error)//Why does compiler sometimes issue a warning, sometimes no???

   [MBProgressHUD hideAllHUDsForView : self.view animated : YES];
   noConnectionHUD = [MBProgressHUD showHUDAddedTo : self.view animated : YES];
   noConnectionHUD.delegate = self;
   noConnectionHUD.mode = MBProgressHUDModeText;
   noConnectionHUD.labelText = @"Load error";
   noConnectionHUD.removeFromSuperViewOnHide = YES;
}

//________________________________________________________________________________________
- (void) hudWasTapped : (MBProgressHUD *) hud
{
   [self refresh];
}

#pragma mark - Navigation (since we replace left navbarbutton).

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}

@end
