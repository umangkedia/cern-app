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
#import "AppDelegate.h"
#import "GCOAuth.h"

namespace {

enum class LoadStage : unsigned char {
   inactive,
   auth,
   rdbRequest,
   originalPageLoad,
   needRefresh
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
   
   UIButton *zoomInBtn;
   UIButton *zoomOutBtn;
   
   NSUInteger zoomLevel;
   int fontSize;
   
   BOOL rdbLoaded;
   BOOL pageLoaded;
}

@synthesize rdbView, pageView, rdbCache, title;

//It has to be included here, since the file can contain
//methods.
#import "Readability.h"

#define  READABILITY_CONTENT_API_DEFINED

//________________________________________________________________________________________
- (void) reachabilityStatusChanged : (Reachability *) current
{
#pragma unused(current)
   using CernAPP::NetworkStatus;
   
   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      [rdbView stopLoading];
      [pageView stopLoading];

      if (currentConnection) {
         [currentConnection cancel];
         currentConnection = nil;
      }

      [self stopSpinner];

      if (stage != LoadStage::inactive) {
         //We show the message and change buttons
         //ONLY if view was loading at the time of this
         //reachability status change.
         stage = LoadStage::needRefresh;
         [self addWebBrowserButtons];
         CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
      }
   }
}

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
      status = 200;
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
- (void) viewDidAppear : (BOOL) animated
{
   [super viewDidAppear : animated];

   CGRect frame = self.view.frame;
   frame.origin = CGPoint();
   
   zoomLevel = 1;
   fontSize = 44;
   
   rdbView.frame = frame;
   pageView.frame = frame;
   
   rdbView.multipleTouchEnabled = YES;
   pageView.multipleTouchEnabled = YES;
   
   rdbLoaded = NO;
   pageLoaded = NO;

   status = 200;
   stage = LoadStage::inactive;

   if (rdbCache && rdbCache.length) {
      //
      [self switchToRdbView];
      [self loadReadabilityCache];
   } else {
      if (!spinner) {
         const CGFloat spinnerSize = 150.f;
         const CGPoint spinnerOrigin = CGPointMake(self.view.frame.size.width / 2 - spinnerSize / 2, self.view.frame.size.height / 2 - spinnerSize / 2);

         spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(spinnerOrigin.x, spinnerOrigin.y, spinnerSize, spinnerSize)];
         spinner.color = [UIColor grayColor];
         [self.view addSubview : spinner];
      }
      
#ifndef READABILITY_CONTENT_API_DEFINED
      [self switchToPageView];
      [self startSpinner];
      [self loadOriginalPage];
#else
      [self switchToRdbView];
      [self startSpinner];
      [self loadHtmlFromReadability];
#endif
   }
}

//________________________________________________________________________________________
- (void) viewWillDisappear : (BOOL) animated
{
   [rdbView stopLoading];
   [pageView stopLoading];
   
   [self stopSpinner];
   
   if (currentConnection) {
      [currentConnection cancel];
      currentConnection = nil;
   }

   stage = LoadStage::inactive;
   status = 200;
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
   articleLink = article.link;
   title = article.title;
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
#pragma unused(webView, error)

   //Web view by Apple is a piece of ...
   //You can first receive didFinishLoad, and later didFailWithError.
   //Or you can receive didFinishLoad many times.
   //Or some ugly mix of both.
   //So web-view delegate is quite a useless crap.

   [self stopSpinner];

   if (pageView.superview) {
      //We're loading an original web-page.
      if (stage != LoadStage::inactive)//didFinish was called already, ignore this error.
         stage = LoadStage::needRefresh;
   } else {
      //simply ignore for the moment.
      stage = LoadStage::inactive;
   }
   
   [self addWebBrowserButtons];
}

//________________________________________________________________________________________
- (void) webViewDidFinishLoad : (UIWebView *) webView
{
#pragma unused(webView)
   [self stopSpinner];

   stage = LoadStage::inactive;
   [self addWebBrowserButtons];
   
   if (pageView.superview)
      pageLoaded = YES;
   else
      rdbLoaded = YES;
}

#pragma mark - Readability and web-view.

//________________________________________________________________________________________
- (void) startSpinner
{
   [spinner setHidden : NO];
   [spinner.superview bringSubviewToFront : spinner];
   [spinner startAnimating];
}

//________________________________________________________________________________________
- (void) stopSpinner
{
   if (spinner && spinner.isAnimating) {
      [spinner stopAnimating];
      [spinner setHidden : YES];
   }
}

//________________________________________________________________________________________
- (void) loadReadabilityCache
{
   assert(rdbCache != nil && rdbCache.length && "loadReadabilityCache, no cache");
   
   NSString * const cssPath = [[NSBundle mainBundle] pathForResource : @"ArticleCSS" ofType:@"css"];
   NSMutableString *htmlString = [NSMutableString stringWithFormat :
                                                @"<html><head><link rel='stylesheet' type='text/css' "
                                                "href='file://%@'></head><body></p></body></html><h1>%@</h1>%@<p class='read'>",
                                  cssPath, title, rdbCache];

   [rdbView loadHTMLString : htmlString baseURL : nil];
}

//________________________________________________________________________________________
- (void) loadHtmlFromReadability
{
   assert(currentConnection == nil && "loadHtmlFromReadability, connection is active");

   id delegateBase = [UIApplication sharedApplication].delegate;
   assert([delegateBase isKindOfClass : [AppDelegate class]] &&
          "loadHtmlFromReadability, app delegate has a wrong type");
   
   AppDelegate * const appDelegate = (AppDelegate *)delegateBase;
   if (appDelegate.OAuthToken && appDelegate.OAuthTokenSecret)
      //We try to re-use OAuth tokens (if they don't expire yet).
      [self readabilityParseHtml];
   else
      [self readabilityAuth];
}

//________________________________________________________________________________________
- (BOOL) extractAuthTokens
{
   assert(stage == LoadStage::auth && "extractAuthTokens, wrong stage");
   assert(responseData != nil && "extractAuthTokens, response data is nil");
   
   //Delegate.
   id delegateBase = [UIApplication sharedApplication].delegate;
   assert([delegateBase isKindOfClass : [AppDelegate class]] &&
          "extractAuthTokens, app delegate has a wrong type");
   AppDelegate * const appDelegate = (AppDelegate *)delegateBase;
   appDelegate.OAuthToken = nil, appDelegate.OAuthTokenSecret = nil;
   
   //Parse the responce.
   NSString *OAuthToken = nil;
   NSString *OAuthTokenSecret = nil;
   NSString *OAuthConfirm = nil;

   NSString * const response = [[NSString alloc] initWithData : responseData encoding : NSUTF8StringEncoding];
   NSArray * const components = [response componentsSeparatedByString : @"&"];
   
   for (NSString *component in components) {
      NSArray *pair = [component componentsSeparatedByString:@"="];
      assert(pair.count == 2);
      if ([(NSString *)pair[0] isEqualToString : @"oauth_token_secret"])
         OAuthTokenSecret = (NSString *)pair[1];
      else if ([(NSString *)pair[0] isEqualToString : @"oauth_token"])
         OAuthToken = (NSString *)pair[1];
      else if ([(NSString *)pair[0] isEqualToString : @"oauth_callback_confirmed"])
         OAuthConfirm = (NSString *)pair[1];
   }
   
   if (OAuthToken && OAuthTokenSecret && OAuthConfirm && [OAuthConfirm isEqualToString : @"true"]) {
      appDelegate.OAuthToken = OAuthToken;
      appDelegate.OAuthTokenSecret = OAuthTokenSecret;
      
      return YES;
   }
   
   return NO;
}

//________________________________________________________________________________________
- (void) loadOriginalPage
{
   assert(currentConnection == nil && "loadOriginalPage, has an active connection");

   using CernAPP::NetworkStatus;

   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      [self stopSpinner];
      CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
      stage = LoadStage::needRefresh;
      //Set a HUD with error message here!
      [self addWebBrowserButtons];//
   } else {
      //Load original page.
      assert(articleLink != nil && "loadOriginalPage, articleLink is nil");

      stage = LoadStage::originalPageLoad;
      NSURL * const url = [NSURL URLWithString : articleLink];
      NSURLRequest * const request = [NSURLRequest requestWithURL : url];
      [pageView loadRequest : request];
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
   
   if (status != 200) {
      [currentConnection cancel];
      currentConnection = nil;
      
      if (stage == LoadStage::auth) {
         //Load original page, we can not try authorization again (it can fail again and again).
         [self switchToPageView];
         [self loadOriginalPage];
      } else if (status == 401) {
         //Looks like our auth tokens expired.
         [self switchToRdbView];//select rdb view, if not yet.
         [self readabilityAuth];
      }
   }
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

   if (stage == LoadStage::auth) {
      //Ok, we, probably, received tokens, try to extract them.
      if ([self extractAuthTokens])
         [self readabilityParseHtml];
      else {
         [self switchToPageView];
         [self loadOriginalPage];
      }
   } else {
      //We, probably, have content parsed from Readability.
      if (![self extractReadabilityContent]) {
         [self switchToPageView];
         [self loadOriginalPage];
      }
   }
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didFailWithError : (NSError *) error
{
#pragma unused(connection)

   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connection:didFailWithError:, wrong stage");
   
   currentConnection = nil;

   //Something is wrong with readability, either auth. failed
   //or readability parse stage, do not try anything else,
   //load the original page.
   [self loadOriginalPage];
}

#pragma mark - "Browser"
//________________________________________________________________________________________
- (void) changeTextSize
{
   NSString * const jsString = [[NSString alloc] initWithFormat : @"document.getElementsByTagName('body')[0].style.fontSize=%d", fontSize];
   [rdbView stringByEvaluatingJavaScriptFromString : jsString];
}

//________________________________________________________________________________________
- (void) sendArticle
{
}

//________________________________________________________________________________________
- (void) flipWebViews
{
   const UIViewAnimationOptions transitionOptions = UIViewAnimationOptionTransitionFlipFromLeft;

   if (rdbView.superview) {
      //Switch to original web-page.
      [rdbView stopLoading];//?
      [UIView transitionFromView : rdbView toView : pageView duration : 1.f options : transitionOptions completion : ^(BOOL finished) {
         if (finished) {
            stage = LoadStage::inactive;
            if (!pageLoaded) {
               [self startSpinner];
               [self hideWebBrowserButtons];
               [self loadOriginalPage];
            } else
               [self addWebBrowserButtons];
         }
      }];

   } else {
      [pageView stopLoading];
      [UIView transitionFromView : pageView toView : rdbView duration : 1.f options : transitionOptions completion : ^(BOOL finished) {
         if (finished) {
            stage = LoadStage::inactive;
            if (!rdbLoaded) {
               [self startSpinner];
               [self loadReadabilityCache];
            } else
               [self addWebBrowserButtons];
         }
      }];      
   }
}

//________________________________________________________________________________________
- (void) zoomIn
{
   if (zoomLevel + 1 == 5)
      zoomInBtn.enabled = NO;
   else if (zoomLevel == 1)
      zoomOutBtn.enabled = YES;

   ++zoomLevel;   
   fontSize += 4;

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
   fontSize -= 4;
   
   [self changeTextSize];
}

//________________________________________________________________________________________
- (void) refresh
{

}

#pragma mark - GUI adjustments.

//________________________________________________________________________________________
- (void) addWebBrowserButtons
{
   if (stage == LoadStage::needRefresh) {
      //We have an error at some stage.
      if (rdbView.superview) {
         //Network connection was lost before I even tried to load
         //original page without readability.
         //I need ONLY refresh button.
         UIButton * const refreshBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [refreshBtn setBackgroundImage : [UIImage imageNamed:@"refresh.png"] forState : UIControlStateNormal];
         [refreshBtn addTarget : self action : @selector(refresh) forControlEvents : UIControlEventTouchUpInside];
         refreshBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);
         
         UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : refreshBtn];//well, not a button but a group of them.
         self.navigationItem.rightBarButtonItem = backButton;
      } else {
         assert(pageView.superview && "addWebBrowserButton, neither rdbView nor pageView are visible");
         if (rdbLoaded) {
            //We have a readability processed data and can switch back to this view.
            //Thus we need 2 buttons: "refresh", "back to readability".
            UIButton * const refreshBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [refreshBtn setBackgroundImage : [UIImage imageNamed:@"refresh.png"] forState : UIControlStateNormal];
            [refreshBtn addTarget : self action : @selector(refresh) forControlEvents : UIControlEventTouchUpInside];
            refreshBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);
            
            UIButton * const flipBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [flipBtn setBackgroundImage:[UIImage imageNamed:@"bookmarks.png"] forState:UIControlStateNormal];
            [flipBtn addTarget : self action : @selector(flipWebViews) forControlEvents : UIControlEventTouchUpInside];
            flipBtn.frame = CGRectMake(28.f, 0.f, 22.f, 22.f);
            
            UIView * const parentView = [[UIView alloc] initWithFrame : CGRect()];
            parentView.frame = CGRectMake(0.f, 0.f, 50.f, 22.f);
            [parentView addSubview : flipBtn];
            [parentView addSubview : refreshBtn];
            
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : parentView];//well, not a button but a group of them.
            self.navigationItem.rightBarButtonItem = backButton;
         } else {
            //Only one button.
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem : UIBarButtonSystemItemRefresh
                                                      target : self action : @selector(refresh)];
         }
      }
   } else {
      //No errors.
      if (rdbView.superview) {
         UIButton * const actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
         [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
         actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);

         UIButton * const origPageBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [origPageBtn setBackgroundImage : [UIImage imageNamed : @"globe.png"] forState : UIControlStateNormal];
         [origPageBtn addTarget : self action : @selector(flipWebViews) forControlEvents : UIControlEventTouchUpInside];
         origPageBtn.frame = CGRectMake(28.f, 0.f, 22.f, 22.f);

         zoomInBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [zoomInBtn setBackgroundImage : [UIImage imageNamed : @"zoomin.png"] forState : UIControlStateNormal];
         [zoomInBtn addTarget : self action : @selector(zoomIn) forControlEvents : UIControlEventTouchUpInside];
         zoomInBtn.frame = CGRectMake(56.f, 0.f, 22.f, 22.f);
         
         zoomOutBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [zoomOutBtn addTarget : self action : @selector(zoomOut) forControlEvents : UIControlEventTouchUpInside];
         [zoomOutBtn setBackgroundImage : [UIImage imageNamed : @"zoomout.png"] forState : UIControlStateNormal];
         zoomOutBtn.frame = CGRectMake(84.f, 0.f, 22.f, 22.f);

         UIView * const parentView = [[UIView alloc] initWithFrame : CGRectMake(0.f, 0.f, 106.f, 22.f)];
         [parentView addSubview : actionBtn];
         [parentView addSubview : origPageBtn];
         [parentView addSubview : zoomInBtn];
         [parentView addSubview : zoomOutBtn];
         
         if (zoomLevel == 1)
            zoomOutBtn.enabled = NO;
         else if (zoomLevel == 5)
            zoomInBtn.enabled = NO;
         
         actionBtn.enabled = NO;
         
         UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : parentView];//well, not a button but a group of them.
         self.navigationItem.rightBarButtonItem = backButton;
      } else {
         //"Send" button and "back to readability".
         if (rdbLoaded) {
            UIButton * const actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
            [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
            actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);
            
            UIButton * const flipBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [flipBtn setBackgroundImage:[UIImage imageNamed:@"bookmarks.png"] forState : UIControlStateNormal];
            [flipBtn addTarget : self action : @selector(flipWebViews) forControlEvents : UIControlEventTouchUpInside];
            flipBtn.frame = CGRectMake(28.f, 0.f, 22.f, 22.f);
            
            UIView * const parentView = [[UIView alloc] initWithFrame : CGRect()];
            parentView.frame = CGRectMake(0.f, 0.f, 50.f, 22.f);
            [parentView addSubview : flipBtn];
            [parentView addSubview : actionBtn];
            
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : parentView];//well, not a button but a group of them.
            self.navigationItem.rightBarButtonItem = backButton;

            actionBtn.enabled = NO;
         } else {
            //Only send.
            UIButton * const actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
            [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
            actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);
            
            actionBtn.enabled = NO;
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : actionBtn];//well, not a button but a group of them.
            self.navigationItem.rightBarButtonItem = backButton;
         }
      }
   }
}

//________________________________________________________________________________________
- (void) hideWebBrowserButtons
{
   self.navigationItem.rightBarButtonItem = nil;
}

//________________________________________________________________________________________
- (void) switchToPageView
{
   //Non-animated switch.
   if (rdbView.superview)
      [rdbView removeFromSuperview];
   if (!pageView.superview)
      [self.view addSubview : pageView];
   
   if (!spinner.hidden)
      [spinner.superview bringSubviewToFront : spinner];
}

//________________________________________________________________________________________
-(void) switchToRdbView
{
   //Non-animated switch.
   if (pageView.superview)
      [pageView removeFromSuperview];
   if (!rdbView.superview)
      [self.view addSubview : rdbView];

   if (!spinner.hidden)
      [spinner.superview bringSubviewToFront : spinner];
}

@end
