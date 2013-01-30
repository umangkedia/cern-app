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
#import "Reachability.h"
#import "GCOAuth.h"

namespace {

enum class LoadStage : unsigned char {
   inactive,
   auth,
   rdbRequest,
   originalPageLoad
};

}

@implementation ArticleDetailViewController {
   NSString *articleLink;
   UIActivityIndicatorView *spinner;
   
   Reachability *internetReach;
   //
   LoadStage stage;
   NSInteger status;
   NSMutableData *responseData;
   
   NSURLConnection *currentConnection;
   
   UIButton *origPageBtn;
   UIButton *zoomInBtn;
   UIButton *zoomOutBtn;
   UIButton *actionBtn;
   
   NSUInteger zoomLevel;
   int fontSize;
}

@synthesize contentWebView, contentString, loadOriginalLink, title;

//It has to be included here, since the file can contain
//methods.
#import "Readability.h"

//________________________________________________________________________________________
- (void) reachabilityStatusChanged : (Reachability *) current
{
#pragma unused(current)
   using CernAPP::NetworkStatus;
   
   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      [self.contentWebView stopLoading];
      if (currentConnection) {
         [currentConnection cancel];
         currentConnection = nil;
         stage = LoadStage::inactive;
      }

      [self stopSpinner];
      CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
   }
}

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
      // Custom initialization
      stage = LoadStage::inactive;
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
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   [super viewDidAppear : animated];

   status = 200;
   stage = LoadStage::inactive;

   if (loadOriginalLink && articleLink) {
      if (!spinner) {
         const CGFloat spinnerSize = 150.f;
         const CGPoint spinnerOrigin = CGPointMake(self.view.frame.size.width / 2 - spinnerSize / 2, self.view.frame.size.height / 2 - spinnerSize / 2);

         spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(spinnerOrigin.x, spinnerOrigin.y, spinnerSize, spinnerSize)];
         spinner.color = [UIColor grayColor];
         [self.view addSubview : spinner];
      }
      
      [spinner setHidden : NO];
      [spinner startAnimating];

#ifndef READABILITY_CONTENT_API_DEFINED
      [self loadOriginalPage];
#else
      [self readabilityAuth];
#endif
   } else if (self.contentString)
      [self.contentWebView loadHTMLString : self.contentString baseURL : nil];
}

//________________________________________________________________________________________
- (void) viewWillDisappear : (BOOL)animated
{
   [self.contentWebView stopLoading];
   [self stopSpinner];
   if (currentConnection) {
      [currentConnection cancel];
      currentConnection = nil;
   }

   stage = LoadStage::inactive;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [[NSNotificationCenter defaultCenter] addObserver : self selector : @selector(reachabilityStatusChanged:) name : CernAPP::reachabilityChangedNotification object : nil];
   internetReach = [Reachability reachabilityForInternetConnection];
   [internetReach startNotifier];
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
   title = article.title;
   
   NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"readOriginalArticle" ofType:@"png"];
   NSString *cssPath = [[NSBundle mainBundle] pathForResource:@"ArticleCSS" ofType:@"css"];
   NSMutableString *htmlString = [NSMutableString stringWithFormat:@"<html><head><link rel='stylesheet' type='text/css' href='file://%@'></head><body><h1>%@</h1><h2>%@</h2>%@<p class='read'><a href='%@'><img src='file://%@' /></a></p></body></html>", cssPath, article.title, dateString, body, link, imgPath];

   self.contentString = htmlString;
   [self.contentWebView loadHTMLString : self.contentString baseURL : nil];//TP: this is actually never gets called - contentWebView is nil here.
}

//________________________________________________________________________________________
/*
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
*/
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
      [[UIApplication sharedApplication] openURL : [request URL]];
      return NO;
   }

   return YES;
}

//________________________________________________________________________________________
- (void) webView : (UIWebView *) webView didFailLoadWithError : (NSError *) error
{
   [self stopSpinner];
   stage = LoadStage::inactive;
}

//________________________________________________________________________________________
- (void) webViewDidFinishLoad : (UIWebView *) webView
{
   //As usually, Apple has a bug or at least bad documentation:
   //scale pages to fit property does not work with some pages (or UIWebView does some
   //undocumented work under the hood, ignoring this property),
   //probably, because of something like this: "<meta name="viewport" content="width=device-width, initial-scale = 1, user-scalable = yes" />"

   [self stopSpinner];
   stage = LoadStage::inactive;
   [self addWebBrowserButtons];
}

#pragma mark - Readability and web-view.

//________________________________________________________________________________________
- (void) stopSpinner
{
   if (spinner && spinner.isAnimating) {
      [spinner stopAnimating];
      [spinner setHidden : YES];
   }
}

//________________________________________________________________________________________
- (void) loadOriginalPage
{
   assert(stage != LoadStage::originalPageLoad && "loadOriginalPage, wrong stage");
   assert(currentConnection == nil && "loadOriginalPage, has an active connection");

   using CernAPP::NetworkStatus;
   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      [self stopSpinner];
      CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
      stage = LoadStage::inactive;
   } else {
      stage = LoadStage::originalPageLoad;
      //Either authentication or parsing failed, try to load original page.
      assert(articleLink != nil && "loadOriginalPage, articleLink is nil");
      NSURL * const url = [NSURL URLWithString : articleLink];      
      NSURLRequest * const request = [NSURLRequest requestWithURL : url];
      [self.contentWebView loadRequest : request];
   }
}

#pragma mark - NSURLConnectionDelegate and NSURLConnectionDataDelegate.

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveResponse : (NSURLResponse *) response
{
#pragma unused(connection)
   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connection:didReceiveResponse:, wrong stage");
   assert(response != nil && "connection:didReceiveResponse:, parameter 'response' is nil");

   if ([response isKindOfClass : [NSHTTPURLResponse class]])
      status = [(NSHTTPURLResponse *)response statusCode];
   else
      status = 200;//???

   if (!responseData)
      responseData = [[NSMutableData alloc] init];
   
   [responseData setLength : 0];
   
   if (status != 200)
      NSLog(@"got error %d", status);
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveData : (NSData *) data
{
#pragma unused(connection)
   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connection:didReceiveData:, wrong stage");
   assert(responseData != nil && "connection:didReceiveData:, 'responseData' is nil");
   
   [responseData appendData : data];
}

//________________________________________________________________________________________
- (void) connectionDidFinishLoading : (NSURLConnection *) connection
{
   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connectionDidFinishLoading:, wrong stage");

   using CernAPP::NetworkStatus;

   currentConnection = nil;

#ifdef READABILITY_CONTENT_API_DEFINED
   if (status != 200)
      //Something bad happened either during auth. or parsing.
      [self loadOriginalPage];
   else if (stage == LoadStage::auth)
      //We have OAuth tokens.
      [self readabilityParse];
   else
      //We have an extracted content.
      [self loadExtractedContent];
#endif
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didFailWithError : (NSError *) error
{
#pragma unused(connection)

   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connection:didFailWithError:, wrong stage");
   
   currentConnection = nil;

#ifdef READABILITY_CONTENT_API_DEFINED
   [self loadOriginalPage];
#endif
}

#pragma mark - "Browser"
//________________________________________________________________________________________
- (void) changeTextSize
{
   NSString *jsString = [[NSString alloc] initWithFormat : @"document.getElementsByTagName('body')[0].style.fontSize=%d", fontSize];
   [self.contentWebView stringByEvaluatingJavaScriptFromString : jsString];
}

//________________________________________________________________________________________
- (void) sendArticle
{
}

//________________________________________________________________________________________
- (void) switchToOriginalPage
{
}

//________________________________________________________________________________________
- (void) zoomIn
{
   if (zoomLevel + 1 == 5)
      zoomInBtn.enabled = NO;
   else if (zoomLevel == 1)
      zoomOutBtn.enabled = YES;

   ++zoomLevel;   
   fontSize += 8;

   [self changeTextSize];   
}

//________________________________________________________________________________________
- (void) zoomOut
{
   if (zoomLevel - 1 < 2)
      zoomOutBtn.enabled = NO;
   else
      zoomInBtn.enabled = YES;
   
   --zoomLevel;
   fontSize -= 8;
   
   [self changeTextSize];
}

#pragma mark - GUI adjustments.

//________________________________________________________________________________________
- (void) addWebBrowserButtons
{
#ifdef READABILITY_CONTENT_API_DEFINED
   actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
   [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
   [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
   actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);

   origPageBtn = [UIButton buttonWithType : UIButtonTypeCustom];
   [origPageBtn setBackgroundImage : [UIImage imageNamed : @"globe.png"] forState : UIControlStateNormal];
   [origPageBtn addTarget : self action : @selector(switchToOriginalPage) forControlEvents : UIControlEventTouchUpInside];
   origPageBtn.frame = CGRectMake(24.f, 0.f, 22.f, 22.f);

   zoomInBtn = [UIButton buttonWithType : UIButtonTypeCustom];
   [zoomInBtn setBackgroundImage : [UIImage imageNamed : @"zoomin.png"] forState : UIControlStateNormal];
   [zoomInBtn addTarget : self action : @selector(zoomIn) forControlEvents : UIControlEventTouchUpInside];
   zoomInBtn.frame = CGRectMake(48.f, 0.f, 22.f, 22.f);
   
   zoomOutBtn = [UIButton buttonWithType : UIButtonTypeCustom];
   [zoomOutBtn addTarget : self action : @selector(zoomOut) forControlEvents : UIControlEventTouchUpInside];
   [zoomOutBtn setBackgroundImage : [UIImage imageNamed : @"zoomout.png"] forState : UIControlStateNormal];
   zoomOutBtn.frame = CGRectMake(72.f, 0.f, 22.f, 22.f);

   UIView * const view = [[UIView alloc] initWithFrame : CGRectMake(0.f, 0.f, 96.f, 22.f)];
   [view addSubview : actionBtn];
   [view addSubview : origPageBtn];
   [view addSubview : zoomInBtn];
   [view addSubview : zoomOutBtn];
   
   zoomOutBtn.enabled = NO;
#else
   actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
   [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
   [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
   actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);

   UIView * const view = [[UIView alloc] initWithFrame : CGRectMake(0.f, 0.f,  22.f, 22.f)];
   [view addSubview : actionBtn];
#endif

   UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : view];
   self.navigationItem.rightBarButtonItem = backButton;
   
   zoomLevel = 1;
   fontSize = 24;
}

@end
