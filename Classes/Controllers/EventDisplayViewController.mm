//
//  EventDisplayViewController.m
//  CERN App
//
//  Created by Eamon Ford on 7/15/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <cassert>

#import <Availability.h>

#import "EventDisplayViewController.h"
#import "ApplicationErrors.h"
#import "GuiAdjustment.h"
#import "Reachability.h"
#import "DeviceCheck.h"

//We compile as Objective-C++, in C++ const have internal linkage ==
//no need for static or unnamed namespace.
NSString * const sourceDescription = @"Description";
NSString * const sourceBoundaryRects = @"Boundaries";
NSString * const resultImage = @"Image";
NSString * const resultLastUpdate = @"Last Updated";
NSString * const sourceURL = @"URL";

using CernAPP::NetworkStatus;

@implementation EventDisplayViewController {
   unsigned loadingSource;
   NSURLConnection *currentConnection;
   NSMutableData *imageData;
   NSDate *lastUpdated;
   
   Reachability *internetReach;
   MBProgressHUD *noConnectionHUD;
}

//________________________________________________________________________________________
- (void) reachabilityStatusChanged : (Reachability *) current
{
   #pragma unused(current)
   
   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      if (currentConnection) {
         [currentConnection cancel];
         currentConnection = nil;
         
         loadingSource = 0;
         imageData = nil;
         [self removeSpinners];

         CernAPP::ShowErrorAlertIfTopLevel(@"Please, check network!", @"Close", self);
      }
   }
}

//________________________________________________________________________________________
- (bool) hasConnection
{
   return internetReach && [internetReach currentReachabilityStatus] != NetworkStatus::notReachable;
}

@synthesize segmentedControl, sources, downloadedResults, scrollView, refreshButton, pageControl, titleLabel, dateLabel, pageLoaded;

//________________________________________________________________________________________
- (id)initWithCoder : (NSCoder *)aDecoder
{
   if (self = [super initWithCoder:aDecoder]) {
      self.sources = [NSMutableArray array];
      numPages = 0;
      loadingSource = 0;
   }

   return self;
}

//________________________________________________________________________________________
- (void) dealloc
{
   [internetReach stopNotifier];
   [[NSNotificationCenter defaultCenter] removeObserver : self];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];

   CGRect titleViewFrame = CGRectMake(0.0, 0.0, 200.0, 44.0);
   UIView *titleView = [[UIView alloc] initWithFrame:titleViewFrame];
   titleView.backgroundColor = [UIColor clearColor];

   titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, titleView.frame.size.width, 24.0)];
   titleLabel.backgroundColor = [UIColor clearColor];
   titleLabel.textColor = [UIColor whiteColor];
   titleLabel.font = [UIFont boldSystemFontOfSize:20.0];

   #ifdef __IPHONE_6_0
   titleLabel.textAlignment = NSTextAlignmentCenter;
   #else
   titleLabel.textAlignment = UITextAlignmentCenter;
   #endif

   titleLabel.text = self.title;
   [titleView addSubview:titleLabel];

   dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, titleLabel.frame.size.height, titleView.frame.size.width, titleView.frame.size.height-titleLabel.frame.size.height)];
   dateLabel.backgroundColor = [UIColor clearColor];
   dateLabel.textColor = [UIColor whiteColor];
   dateLabel.font = [UIFont boldSystemFontOfSize:13.0];

   #ifdef __IPHONE_6_0
   dateLabel.textAlignment = NSTextAlignmentCenter ;
   #else
   dateLabel.textAlignment = UITextAlignmentCenter;
   #endif

   [titleView addSubview:dateLabel];

   self.navigationItem.titleView = titleView;

   self.pageControl.numberOfPages = numPages;
   self.scrollView.backgroundColor = [UIColor blackColor];
   
   pageLoaded = NO;
   
   if (![DeviceCheck deviceIsiPad])
      CernAPP::ResetBackButton(self, @"back_button_flat.png");
   
   [[NSNotificationCenter defaultCenter] addObserver : self selector : @selector(reachabilityStatusChanged:) name : CernAPP::reachabilityChangedNotification object : nil];
   internetReach = [Reachability reachabilityForInternetConnection];
   [internetReach startNotifier];
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * numPages, 1.f);

   if (![self hasConnection])
      return;

   [self addSpinners];
   [self refresh : self];
}

//________________________________________________________________________________________
- (void) viewDidUnload
{
    [super viewDidUnload];
    for (UIView *subview in self.scrollView.subviews) {
        if ([subview class] == [UIImageView class]) {
            ((UIImageView *)subview).image = nil;
        }
        [subview removeFromSuperview];
    }
}

//________________________________________________________________________________________
- (void) viewWillDisappear:(BOOL)animated
{
   if (currentConnection)
      [currentConnection cancel];

   [super viewWillDisappear : animated];
}

//________________________________________________________________________________________
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//________________________________________________________________________________________
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    currentPage = self.pageControl.currentPage;
}

//________________________________________________________________________________________
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat oldScreenWidth = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)?[UIScreen mainScreen].bounds.size.height:[UIScreen mainScreen].bounds.size.width;
    
    float scrollViewWidth = self.scrollView.frame.size.width;
    float scrollViewHeight = self.scrollView.frame.size.height;
    self.scrollView.contentSize = CGSizeMake(scrollViewWidth*numPages, 1.0);
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width*currentPage, 0.0)];
    
    [UIView animateWithDuration:duration animations:^{
        for (UIView *subview in self.scrollView.subviews) {
            int page = floor((subview.frame.origin.x - oldScreenWidth / 2) / oldScreenWidth) + 1;
            subview.frame = CGRectMake(scrollViewWidth*page, 0.0, scrollViewWidth, scrollViewHeight);
        }
    }];
}

//________________________________________________________________________________________
- (void)addSourceWithDescription:(NSString *)description URL:(NSURL *)url boundaryRects:(NSArray *)boundaryRects
{
    pageLoaded = NO;
    NSMutableDictionary *source = [NSMutableDictionary dictionary];
    [source setValue : description forKey : sourceDescription];
    [source setValue : url forKey : sourceURL];
    if (boundaryRects) {
        [source setValue : boundaryRects forKey : sourceBoundaryRects];
        // If the image downloaded from this source is going to be divided into multiple images, we will want a separate page for each of these.
        numPages += boundaryRects.count;
    } else {
        numPages += 1;
    }
    [self.sources addObject:source];
}

#pragma mark - Loading event display images

//________________________________________________________________________________________
- (void) reloadPage
{
   [self refresh];
}

//________________________________________________________________________________________
- (void) refresh
{
   [self refresh : self];
}

//________________________________________________________________________________________
- (IBAction) refresh : (id)sender
{
   [MBProgressHUD hideAllHUDsForView : self.view animated : NO];

   if (![self hasConnection]) {
      noConnectionHUD = [MBProgressHUD showHUDAddedTo : self.view animated : NO];
      noConnectionHUD.color = [UIColor redColor];
      noConnectionHUD.delegate = self;
      noConnectionHUD.mode = MBProgressHUDModeText;
      noConnectionHUD.labelText = @"No network";
      noConnectionHUD.removeFromSuperViewOnHide = YES;
      return;
   }

   if (currentConnection)
      [currentConnection cancel];
   
   pageLoaded = NO;

   // If the event display images from a previous load are already in the scrollview, remove all of them before refreshing.
   for (UIView *subview in self.scrollView.subviews) {
      if ([subview class] == [UIImageView class])
         [subview removeFromSuperview];
   }
   
   if ([sources count]) {
      [self addSpinnerToPage : self.pageControl.currentPage];
      self.refreshButton.enabled = NO;
      self.downloadedResults = [NSMutableArray array];
      NSDictionary * const source = [sources objectAtIndex : 0];
      NSURL * const url = [source objectForKey : sourceURL];
      NSURLRequest * const request = [NSURLRequest requestWithURL : url];
      loadingSource = 0;
      imageData = [[NSMutableData alloc] init];
      currentConnection = [[NSURLConnection alloc] initWithRequest : request delegate : self startImmediately : YES];
   }
}

//________________________________________________________________________________________
- (void) synchronouslyDownloadImageForSource : (NSDictionary *) source
{
    // Download the image from the specified source
    NSURL *url = [source objectForKey : sourceURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    UIImage *image = [UIImage imageWithData : data];
    
    NSDate *updated = [self lastModifiedDateFromHTTPResponse:response];

    // Just set the date in the nav bar to the date of the first image, because they should all be pretty much the same anyway
    if (self.downloadedResults.count == 0) {
        self.dateLabel.text = [self timeAgoStringFromDate:updated];
    }
    
    // If the downloaded image needs to be divided into several smaller images, do that now and add each
    // smaller image to the results array.
    NSArray *boundaryRects = [source objectForKey:sourceBoundaryRects];
    if (boundaryRects) {
        for (NSDictionary *boundaryInfo in boundaryRects) {
            NSValue *rectValue = [boundaryInfo objectForKey:@"Rect"];
            CGRect boundaryRect = [rectValue CGRectValue];
            CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, boundaryRect);
            UIImage *partialImage = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            NSDictionary *imageInfo = [NSMutableDictionary dictionary];
            [imageInfo setValue:partialImage forKey:resultImage];
            [imageInfo setValue:[boundaryInfo objectForKey:sourceDescription] forKey:sourceDescription];
            [imageInfo setValue:updated forKey:resultLastUpdate];
            [self.downloadedResults addObject:imageInfo];
            [self addDisplay:imageInfo toPage:self.downloadedResults.count-1];
        }
    } else {    // Otherwise if the image does not need to be divided, just add the image to the results array.
        NSDictionary *imageInfo = [NSMutableDictionary dictionary];
        [imageInfo setValue:image forKey:resultImage];
        [imageInfo setValue:[source objectForKey:sourceDescription] forKey : sourceDescription];
        [imageInfo setValue:updated forKey:resultLastUpdate];
        [self.downloadedResults addObject:imageInfo];
        [self addDisplay:imageInfo toPage:self.downloadedResults.count-1];
    }
    
    if (self.downloadedResults.count == numPages) {
        self.refreshButton.enabled = YES;
    }
}

//________________________________________________________________________________________
- (NSDate *)lastModifiedDateFromHTTPResponse:(NSHTTPURLResponse *)response
{
    NSDictionary *allHeaderFields = response.allHeaderFields;
    NSString *lastModifiedString = [allHeaderFields objectForKey:@"Last-Modified"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"];
    
    return [dateFormatter dateFromString:lastModifiedString];
}

//________________________________________________________________________________________
- (NSString *)timeAgoStringFromDate:(NSDate *)date
{
    int secondsAgo = abs([date timeIntervalSinceNow]);
    NSString *dateString;
    if (secondsAgo<60*60) {
        dateString = [NSString stringWithFormat:@"%d minutes ago", secondsAgo/60];
    } else if (secondsAgo<60*60*24) {
        dateString = [NSString stringWithFormat:@"%0.1f hours ago", (float)secondsAgo/(60*60)];
    } else {
        dateString = [NSString stringWithFormat:@"%0.1f days ago", (float)secondsAgo/(60*60*24)];
    }
    return dateString;
}
        
#pragma mark - UI methods

//________________________________________________________________________________________
- (void)addDisplay:(NSDictionary *)eventDisplayInfo toPage:(int)page
{
   UIImage *image = [eventDisplayInfo objectForKey : resultImage];
   CGRect imageViewFrame = CGRectMake(self.scrollView.frame.size.width*page, 0., self.scrollView.frame.size.width, self.scrollView.frame.size.height);
   UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
   imageView.contentMode = UIViewContentModeScaleAspectFit;
   imageView.image = image;
   [self.scrollView addSubview:imageView];
}

//________________________________________________________________________________________
- (void) addSpinners
{
   for (int i = 0; i< numPages; i++)
      [self addSpinnerToPage : i];
}

//________________________________________________________________________________________
- (void) addSpinnerToPage : (int) page
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.frame = CGRectMake(self.scrollView.frame.size.width*page, 0.0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    [spinner startAnimating];
    [self.scrollView addSubview:spinner];
}

//________________________________________________________________________________________
- (void) removeSpinners
{
   for (UIView * v in self.scrollView.subviews) {
      if ([v isKindOfClass:[UIActivityIndicatorView class]])
         [v removeFromSuperview];
   }
}

//________________________________________________________________________________________
- (void) scrollViewDidScroll : (UIScrollView *)sender
{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

//________________________________________________________________________________________
- (void) scrollToPage : (NSInteger) page
{
 //  assert(page >= 0 && page < [sources count]);
   self.scrollView.contentOffset = CGPointMake(page * self.scrollView.frame.size.width, 0);
   self.pageControl.currentPage = page;
}

#pragma mark - NSURLConnectionDelegate

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveData : (NSData *)data
{
   assert(imageData != nil && "connection:didReceiveData:, imageData is nil");

   [imageData appendData : data];
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveResponse : (NSURLResponse *) response
{
   if ([response isKindOfClass : [NSHTTPURLResponse class]])
      lastUpdated = [self lastModifiedDateFromHTTPResponse : (NSHTTPURLResponse *)response];
   else
      lastUpdated = [NSDate date];

   // Just set the date in the nav bar to the date of the first image, because they should all be pretty much the same anyway
   if (!self.downloadedResults.count)
      self.dateLabel.text = [self timeAgoStringFromDate : lastUpdated];

}

//________________________________________________________________________________________
- (void) connectionDidFinishLoading : (NSURLConnection *) urlConnection
{
   assert(loadingSource < [sources count] && "connectionDidFinishLoading, loadingSource is out of bounds");
   
   if ([imageData length]) {
      UIImage * const newImage = [UIImage imageWithData : imageData];
      if (newImage) {
         NSDictionary * const source = (NSDictionary *)[sources objectAtIndex : loadingSource];
         //
         if (!lastUpdated)//TODO: this "lastUpdated" must be replaced with something more reliable.
            lastUpdated = [NSDate date];

         if (NSArray * const boundaryRects = [source objectForKey : sourceBoundaryRects]) {
            for (NSDictionary *boundaryInfo in boundaryRects) {
               NSValue * const rectValue = (NSValue *)[boundaryInfo objectForKey : @"Rect"];
               const CGRect boundaryRect = [rectValue CGRectValue];
               CGImageRef imageRef(CGImageCreateWithImageInRect(newImage.CGImage, boundaryRect));
               UIImage * const partialImage = [UIImage imageWithCGImage : imageRef];
               CGImageRelease(imageRef);
               NSDictionary *imageInfo = [NSMutableDictionary dictionary];
               [imageInfo setValue : partialImage forKey : resultImage];
               [imageInfo setValue : [boundaryInfo objectForKey : sourceDescription] forKey : sourceDescription];
               [imageInfo setValue : lastUpdated forKey : resultLastUpdate];
               [self.downloadedResults addObject : imageInfo];
               [self addDisplay : imageInfo toPage : self.downloadedResults.count - 1];
            }
         } else {
            // Otherwise if the image does not need to be divided, just add the image to the results array.
            NSDictionary * const imageInfo = [NSMutableDictionary dictionary];
            [imageInfo setValue : newImage forKey : resultImage];
            [imageInfo setValue : [source objectForKey : sourceDescription] forKey : sourceDescription];
            [imageInfo setValue : lastUpdated forKey : resultLastUpdate];
            [self.downloadedResults addObject : imageInfo];
            [self addDisplay : imageInfo toPage : self.downloadedResults.count - 1];
         }
      }
   }
   
   if (loadingSource + 1 < [sources count]) {
      //We have to continue.
      ++loadingSource;

      NSDictionary * const source = [sources objectAtIndex : loadingSource];
      NSURL * const url = [source objectForKey : sourceURL];
      NSURLRequest * const request = [NSURLRequest requestWithURL : url];
      imageData = [[NSMutableData alloc] init];
      currentConnection = [[NSURLConnection alloc] initWithRequest : request delegate : self startImmediately : YES];
   } else {
      currentConnection = nil;
      imageData = nil;
      loadingSource = 0;
      pageLoaded = YES;
      self.refreshButton.enabled = YES;
      [self removeSpinners];
   }
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) urlConnection didFailWithError : (NSError *) error
{
   if (loadingSource + 1 < [sources count]) {
      ++loadingSource;
      NSDictionary * const source = [sources objectAtIndex : loadingSource];
      NSURL * const url = [source objectForKey : sourceURL];
      NSURLRequest * const request = [NSURLRequest requestWithURL : url];
      imageData = [[NSMutableData alloc] init];
      currentConnection = [[NSURLConnection alloc] initWithRequest : request delegate : self startImmediately : YES];
   } else {
      currentConnection = nil;
      imageData = nil;
      loadingSource = 0;
      pageLoaded = YES;
      self.refreshButton.enabled = YES;
   }
}

#pragma mark - Navigation (since we replace left navbarbutton).

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}


@end
