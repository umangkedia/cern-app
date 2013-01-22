#import <cassert>

#import <UIKit/UIKit.h>

#import "ImageDownloader.h"

//
//Small and trivial class - wrapper for a NSURLConnection to
//download images (thumbnails and icons). Inspired by Apple's
//LazyTableImages code sample.
//

@implementation ImageDownloader {
   NSMutableData *imageData;
   NSURLConnection *imageConnection;
   NSString *urlString;
}

@synthesize delegate, indexPathInTableView, image;

//________________________________________________________________________________________
- (id) initWithURLString : (NSString *) url
{
   assert(url != nil && "initWithURLString:, parameter 'url' is nil");
   
   if (self = [super init]) {
      urlString = url;
      imageData = nil;
      imageConnection = nil;
   }
   
   return self;
}

//________________________________________________________________________________________
- (void) dealloc
{
   [self cancelDownload];
}

//________________________________________________________________________________________
- (void) startDownload
{
   assert(imageConnection == nil && "startDownload, download started already");

   image = nil;
   imageData = [[NSMutableData alloc] init];
   imageConnection = [[NSURLConnection alloc] initWithRequest :
                      [NSURLRequest requestWithURL : [NSURL URLWithString : urlString]]
                      delegate : self];
}

//________________________________________________________________________________________
- (void) cancelDownload
{
   if (imageConnection) {
      [imageConnection cancel];
      imageConnection = nil;
      imageData = nil;
   }
}

#pragma mark - NSURLConnectionDelegate

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveData : (NSData *) data
{
   assert(connection != nil && "connection:didReceiveData:, parameter 'connection' is nil");
   assert(data != nil && "connection:didReceiveData:, parameter 'data' is nil");
   assert(imageData != nil && "connection:didReceiveData:, imageData is nil");
   
   if (connection != imageConnection) {
      //I do not think this can ever happen :)
      NSLog(@"imageDownloader, error: connection:didReceiveData:, data from unknown connection");
      return;
   }
   
   [imageData appendData : data];
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didFailWithError : (NSError *) error
{
#pragma unused(error)

   assert(connection != nil && "connection:didFailWithError:, parameter 'connection' is nil");

   if (connection != imageConnection) {
      //Can this ever happen?
      NSLog(@"imageDownloader, error: connection:didFaileWithError:, unknown connection");
      return;
   }

   imageData = nil;
   imageConnection = nil;
   
   assert(indexPathInTableView != nil &&
          "connection:didFailWithError:, indexPathInTableView is nl");

   [delegate imageDownloadFailed : indexPathInTableView];
}

//________________________________________________________________________________________
- (void) connectionDidFinishLoading : (NSURLConnection *) connection
{
   assert(connection != nil && "connectionDidFinishLoading:, parameter 'connection' is nil");
   assert(image == nil && "connectionDidFinishLoading:, image must be nil");
   
   if (connection != imageConnection) {
      NSLog(@"imageDownloader, error: connectionDidFinishLoading:, unknown connection");
      return;
   }
   
   if (imageData.length)
      image = [[UIImage alloc] initWithData : imageData];

   assert(indexPathInTableView != nil && "connectionDidFinishLoading:, indexPathInTableView is nil");

   [delegate imageDidLoad : indexPathInTableView];

   imageConnection = nil;
   imageData = nil;
}

@end

