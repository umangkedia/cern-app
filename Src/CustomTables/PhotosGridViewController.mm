//
//  PhotosViewController.m
//  CERN App
//
//  Created by Eamon Ford on 6/27/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "PhotosGridViewController.h"
#import "ECSlidingViewController.h"
#import "CernMediaMARCParser.h"
#import "PhotoGridViewCell.h"
#import "ApplicationErrors.h"
#import "MBProgressHUD.h"

@implementation PhotosGridViewController {
   MBProgressHUD *noConnectionHUD;
   
   NSUInteger selectedSection;
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
- (void) viewDidLoad
{
   [super viewDidLoad];
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
      //TODO:!!!
   }
}

//________________________________________________________________________________________
- (void) refresh
{
   if (photoDownloader.numberOfPhotoSets == 0 && !photoDownloader.isDownloading) {
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
         [self refresh];
      }
   }
}

#pragma mark - UICollectionViewDataSource

//________________________________________________________________________________________
- (NSInteger) numberOfSectionsInCollectionView : (UICollectionView *) collectionView
{
#pragma unused(collectionView)
   return [photoDownloader numberOfPhotoSets];//Actually, we can have several sections?
}

//________________________________________________________________________________________
- (NSInteger) collectionView : (UICollectionView *) collectionView numberOfItemsInSection : (NSInteger) section
{
#pragma unused(collectionView, section)
   return [photoDownloader numberOfImagesInSet : section];
}

//________________________________________________________________________________________
- (UICollectionViewCell *) collectionView : (UICollectionView *) collectionView cellForItemAtIndexPath : (NSIndexPath *) indexPath
{
   assert(collectionView != nil && "collectionView:cellForItemAtIndexPath:, parameter 'collectionView' is nil");
   assert(indexPath != nil && "collectionView:cellForItemAtIndexPath:, parameter 'indexPath' is nil");

   UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier : @"PhotoCell" forIndexPath : indexPath];
   assert(!cell || [cell isKindOfClass : [PhotoGridViewCell class]] &&
          "collectionView:cellForItemAtIndexPath:, reusable cell has a wrong type");
   
   if (!cell)
      cell = [[PhotoGridViewCell alloc] initWithFrame : CGRect()];
   
   PhotoGridViewCell * const photoCell = (PhotoGridViewCell *)cell;
   photoCell.imageView.image = [photoDownloader tuhmbnailForIndex : indexPath.row fromPhotoset : indexPath.section];
   
   return photoCell;
}

#pragma mark - UICollectionViewDelegate

//________________________________________________________________________________________
- (void) collectionView : (UICollectionView *) collectionView didSelectItemAtIndexPath : (NSIndexPath *) indexPath
{
   assert(collectionView != nil && "collectionView:didSelectItemAtIndexPath:, parameter 'collectionView' is nil");
   assert(indexPath != nil && "collectionView:didSelectItemAtIndexPath:, parameter 'indexPath' is nil");
   assert(indexPath.section >= 0 && "collectionView:didSelectItemAtIndexPath:, indexPath.section is negative");

   selectedSection = indexPath.section;
   assert(selectedSection < photoDownloader.numberOfPhotoSets && "collectionView:didSelectItemAtIndexPath:, section is out of bounds");

   MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate : self];
   browser.displayActionButton = YES;
   [browser setInitialPageIndex : indexPath.row];

   UINavigationController * const navController = [[UINavigationController alloc] initWithRootViewController : browser];
   navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
   [self presentViewController : navController animated : YES completion : nil];
}


#pragma mark - PhotoDownloaderDelegate methods

//________________________________________________________________________________________
- (void) photoDownloaderDidFinish : (PhotoDownloader *) photoDownloader
{
   [MBProgressHUD hideHUDForView : self.view animated : YES];
   [self.collectionView reloadData];
}

//________________________________________________________________________________________
- (void) photoDownloader : (PhotoDownloader *) photoDownloader didDownloadThumbnail : (NSUInteger) imageIndex forSet : (NSUInteger) setIndex
{
   NSIndexPath * const indexPath = [NSIndexPath indexPathForRow : imageIndex inSection : setIndex];

   [self.collectionView reloadItemsAtIndexPaths : @[indexPath]];
}


//________________________________________________________________________________________
- (void) photoDownloader : (PhotoDownloader *) photoDownloader didFailWithError : (NSError *) error
{
#pragma unused(error)
   [MBProgressHUD hideAllHUDsForView : self.view animated : YES];
   noConnectionHUD = [MBProgressHUD showHUDAddedTo : self.view animated : YES];
   noConnectionHUD.delegate = self;
   noConnectionHUD.mode = MBProgressHUDModeText;
   noConnectionHUD.labelText = @"Load error";
   noConnectionHUD.removeFromSuperViewOnHide = YES;
}

//________________________________________________________________________________________
- (void) photoDownloaderDidFinishLoadingThumbnails : (PhotoDownloader *) aPhotoDownloader
{
#pragma unused(aPhotoDownloader)
   [photoDownloader compactData];
   [self.collectionView reloadData];
}

#pragma mark - MWPhotoBrowserDelegate methods

//________________________________________________________________________________________
- (NSUInteger) numberOfPhotosInPhotoBrowser : (MWPhotoBrowser *) photoBrowser
{
#pragma unused(photoBrowser)

   assert(selectedSection < photoDownloader.numberOfPhotoSets &&
          "numberOfPhotosInPhotoBrowser:, selectedSection is out of bounds");

   return [photoDownloader numberOfImagesInSet : selectedSection];
}

//________________________________________________________________________________________
- (MWPhoto *) photoBrowser : (MWPhotoBrowser *) photoBrowser photoAtIndex : (NSUInteger) index
{
#pragma unused(photoBrowser)
   assert(selectedSection < photoDownloader.numberOfPhotoSets &&
          "photoBrowser:photoAtIndex:, selectedSection is out of bounds");

   NSURL * const url = [photoDownloader imageURLForIndex:index fromPhotoset:selectedSection forType : @"jpgA5"];
   return [MWPhoto photoWithURL : url];
}

//________________________________________________________________________________________
- (void) hudWasTapped : (MBProgressHUD *) hud
{
   [self refresh];
}

#pragma mark - Sliding view.

//________________________________________________________________________________________
- (IBAction) revealMenu : (id) sender
{
#pragma unused(sender)
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
