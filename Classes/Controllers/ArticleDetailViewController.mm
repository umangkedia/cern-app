//
//  ArticleDetailViewController.m
//  CERN App
//
//  Created by Eamon Ford on 6/18/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

//Modified by Timur Pocheptsov.

#import "ArticleDetailViewController.h"
#import "ApplicationErrors.h"
#import "NSString+HTML.h"
#import "GuiAdjustment.h"
#import "Reachability.h"
#import "DeviceCheck.h"
#import "Constants.h"

using CernAPP::NetworkStatus;

@implementation ArticleDetailViewController {
   NSString *articleLink;
   UIActivityIndicatorView *spinner;
   
   Reachability *internetReach;
}

@synthesize contentWebView, contentString, loadOriginalLink;

//________________________________________________________________________________________
- (void) reachabilityStatusChanged : (Reachability *) current
{
   #pragma unused(current)
   
   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      [self.contentWebView stopLoading];
      if (spinner && spinner.isAnimating) {
         [spinner stopAnimating];
         [spinner setHidden : YES];
         CernAPP::ShowErrorAlertIfTopLevel(@"Please, check network!", @"Close", self);
      }
   }
}

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil];
   if (self) {
      // Custom initialization
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
- (void) viewWillAppear : (BOOL) animated
{
   if (loadOriginalLink && articleLink) {
      const CGFloat spinnerSize = 150.f;
      const CGPoint spinnerOrigin = CGPointMake(self.view.frame.size.width / 2 - spinnerSize / 2, self.view.frame.size.height / 2 - spinnerSize / 2);
      
      if (!spinner) {
         spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(spinnerOrigin.x, spinnerOrigin.y, spinnerSize, spinnerSize)];
         spinner.color = [UIColor grayColor];
         [self.view addSubview : spinner];
      }
      
      [spinner setHidden : NO];
      [spinner startAnimating];
   
      NSURL * const url = [NSURL URLWithString : articleLink];
      
      NSURLRequest * const request = [NSURLRequest requestWithURL : url];
      [self.contentWebView loadRequest : request];
   } else if (self.contentString)
      [self.contentWebView loadHTMLString : self.contentString baseURL : nil];
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
}

//________________________________________________________________________________________
- (void)viewWillDisappear:(BOOL)animated
{
    [self.contentWebView stopLoading];
    if (spinner && [spinner isAnimating]) {
       [spinner stopAnimating];
       [spinner setHidden : YES];
    }
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   if (![DeviceCheck deviceIsiPad])
      CernAPP::ResetBackButton(self, @"back_button_flat.png");

   [[NSNotificationCenter defaultCenter] addObserver : self selector : @selector(reachabilityStatusChanged:) name : CernAPP::reachabilityChangedNotification object : nil];
   internetReach = [Reachability reachabilityForInternetConnection];
   [internetReach startNotifier];
}

//________________________________________________________________________________________
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
- (void) setContentForArticle : (MWFeedItem *) article
{
   NSString *body = @"";

   // Give "content" a higher priority, but otherwise use "summary"
   if (article.content)
      body = article.content;
   else if (article.summary)
      body = article.summary;

    
   NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
   formatter.dateStyle = NSDateFormatterMediumStyle;
   NSString *dateString = [formatter stringFromDate : article.date];
   if (!dateString)
      dateString = @"";

   NSString *link = article.link;
   articleLink = article.link;
   
   NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"readOriginalArticle" ofType:@"png"];
   NSString *cssPath = [[NSBundle mainBundle] pathForResource:@"ArticleCSS" ofType:@"css"];
   NSMutableString *htmlString = [NSMutableString stringWithFormat:@"<html><head><link rel='stylesheet' type='text/css' href='file://%@'></head><body><h1>%@</h1><h2>%@</h2>%@<p class='read'><a href='%@'><img src='file://%@' /></a></p></body></html>", cssPath, article.title, dateString, body, link, imgPath];

   self.contentString = htmlString;
   [self.contentWebView loadHTMLString : self.contentString baseURL : nil];//TP: this is actually never gets called - contentWebView is nil here.
}

//________________________________________________________________________________________
- (void)setContentForVideoMetadata:(NSDictionary *)videoMetadata
{
    NSString *videoTag = [NSString stringWithFormat:@"<video width='100%%' controls='controls'><source src='%@' type='video/mp4' /></video>", [videoMetadata objectForKey:kVideoMetadataPropertyVideoURL]];
    NSString *titleTag = [NSString stringWithFormat:@"<h1>%@</h1>", [videoMetadata objectForKey:kVideoMetadataPropertyTitle]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    NSString *dateString = [formatter stringFromDate:[videoMetadata objectForKey:kVideoMetadataPropertyDate]];
    NSString *dateTag = [NSString stringWithFormat:@"<h2>%@</h2>", dateString];
    
    NSString *cssPath = [[NSBundle mainBundle] pathForResource:@"ArticleCSS" ofType:@"css"];
    
    NSMutableString *htmlString = [NSMutableString stringWithFormat:@"<html><head><link rel='stylesheet' type='text/css' href='file://%@'></head><body>%@%@%@</body></html>", cssPath, videoTag, titleTag, dateTag];
    
    self.contentString = htmlString;
    [self.contentWebView loadHTMLString:self.contentString baseURL:nil];   
}

//________________________________________________________________________________________
- (void)setContentForTweet:(NSDictionary *)tweet
{
    self.contentString = [[tweet objectForKey:@"text"] stringByLinkifyingURLs];
    [self.contentWebView loadHTMLString:self.contentString baseURL:nil];
}

#pragma mark - UIWebViewDelegate protocol.

//________________________________________________________________________________________
- (BOOL) webView : (UIWebView *) webView shouldStartLoadWithRequest : (NSURLRequest *)request navigationType : (UIWebViewNavigationType) navigationType
{
   if (navigationType == UIWebViewNavigationTypeLinkClicked ) {
      [[UIApplication sharedApplication] openURL:[request URL]];
      return NO;
   }

   return YES;
}

//________________________________________________________________________________________
- (void) webView : (UIWebView *) webView didFailLoadWithError : (NSError *) error
{
   if (spinner && [spinner isAnimating]) {
      [spinner stopAnimating];
      [spinner setHidden : YES];
   }
}

//________________________________________________________________________________________
- (void) webViewDidFinishLoad : (UIWebView *) webView
{
   //As usually, Apple has a bug or at least bad documentation:
   //scale pages to fit property does not work with some pages (or UIWebView does some
   //undocumented work under the hood, ignoring this property),
   //probably, because of something like this: "<meta name="viewport" content="width=device-width, initial-scale = 1, user-scalable = yes" />"

   if (spinner && [spinner isAnimating]) {
      [spinner stopAnimating];
      [spinner setHidden : YES];
   }
   
   /*
   //Many thank to Confused Vorlon for this trick (http://stackoverflow.com/questions/1511707/uiwebview-does-not-scale-content-to-fit)
   if ([self.contentWebView respondsToSelector:@selector(scrollView)]) {
      UIScrollView * const scroll = [self.contentWebView scrollView];
      const CGFloat zoom = self.contentWebView.bounds.size.width / scroll.contentSize.width;
      if (zoom != 1.) {
         [scroll setZoomScale : zoom animated : YES];
      }
   }
   */
}

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}


@end
