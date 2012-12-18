//
//  PhotoDownloader.m
//  CERN App
//
//  Created by Eamon Ford on 7/4/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

//The code was modified/fixed to at least some working state by Timur Pocheptsov.

#import <cassert>

#import "UIImage+SquareScaledImage.h"
#import "PhotoDownloader.h"


@implementation PhotoDownloader {
   CernMediaMARCParser *parser;
}

@synthesize urls, thumbnails, delegate, isDownloading;

//________________________________________________________________________________________
- (id) init
{
   if (self = [super init]) {
      parser = [[CernMediaMARCParser alloc] init];
      parser.delegate = self;
      parser.resourceTypes = @[@"jpgA4", @"jpgA5", @"jpgIcon"];
   }

   return self;
}

//________________________________________________________________________________________
- (NSURL *) url
{
   return parser.url;
}

//________________________________________________________________________________________
- (void) setUrl : (NSURL *) url;
{
   parser.url = url;
}

//________________________________________________________________________________________
- (void) parse
{
   isDownloading = YES;
   urls = [[NSMutableArray alloc] init];
   thumbnails = [NSMutableDictionary dictionary];
   [parser parse];
}

#pragma mark CernMediaMARCParserDelegate methods

//________________________________________________________________________________________
- (void) parser : (CernMediaMARCParser *) aParser didParseRecord : (NSDictionary *) record
{
   //From Eamon:
   // "we will assume that each array in the dictionary has the same number of photo urls".
   
   //From me:
   // No, this assumption does not work :( some images can be omitted - for example, 'jpgIcon'.

   assert(aParser != nil && "parser:didParseRecord:, parameter 'aParser' is null");
   assert(record != nil && "parser:didParseRecord:, parameter 'record' is null");

   {
   NSDictionary * const resources = (NSDictionary *)[record objectForKey : @"resources"];
   assert(resources != nil && "parser:didParseRecord:, no object for the key 'resources' was found");
   
   const NSUInteger nPhotos = ((NSArray *)[resources objectForKey : [aParser.resourceTypes objectAtIndex : 0]]).count;
   for (NSUInteger i = 1, e = aParser.resourceTypes.count; i < e; ++i) {
      NSArray * const typedData = (NSArray *)[resources objectForKey : [aParser.resourceTypes objectAtIndex : i]];
      if (typedData.count != nPhotos) {
         //NSLog(@"GOT A TROUBLE!!! %@", record);
         return;//break;
      }
   }
   }

   // we will assume that each array in the dictionary has the same number of photo urls
   NSMutableDictionary *resources = [record objectForKey:@"resources"];
   const int numPhotosInRecord = ((NSArray *)[resources objectForKey:[parser.resourceTypes objectAtIndex : 0]]).count;

   for (int i = 0; i < numPhotosInRecord; i++) {
      NSMutableDictionary *photo = [NSMutableDictionary dictionary];
      NSArray *resourceTypes = parser.resourceTypes;
      int numResourceTypes = resourceTypes.count;
      for (int j=0; j<numResourceTypes; j++) {
         NSString *currentResourceType = [resourceTypes objectAtIndex:j];
         NSURL *url = [[resources objectForKey:currentResourceType] objectAtIndex:i];
         [photo setObject:url forKey:currentResourceType];
      }
   
      [self.urls addObject:photo];

      // now download the thumbnail for that photo
      int index = self.urls.count-1;
      [self performSelectorInBackground:@selector(downloadThumbnailForIndex:) withObject:[NSNumber numberWithInt:index]];
   }
}

// We will use a synchronous connection running in a background thread to download thumbnails
// because it is much simpler than handling an arbitrary number of asynchronous connections concurrently.

//________________________________________________________________________________________
- (void) downloadThumbnailForIndex : (id) indexNumber
{
    // now download the thumbnail for that photo
    int index = ((NSNumber *)indexNumber).intValue;
    NSDictionary *photo = [self.urls objectAtIndex:index];
    NSURLRequest *request = [NSURLRequest requestWithURL:[photo objectForKey:@"jpgIcon"]];
    NSData *thumbnailData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    UIImage *thumbnailImage = [UIImage imageWithData:thumbnailData];
    
    if (!thumbnailImage)
      thumbnailImage = [UIImage imageNamed : @"image_not_found.png"];
    
    [self.thumbnails setObject:thumbnailImage forKey:[NSNumber numberWithInt:index]];

    /*
    if (thumbnailImage) {
        [self.thumbnails setObject:thumbnailImage forKey:[NSNumber numberWithInt:index]];
    } else {
        NSLog(@"Error downloading thumbnail #%d, will try again.", index);
        [self downloadThumbnailForIndex:[NSNumber numberWithInt:index]];
    }
    */
    
    if (self.thumbnails.count == self.urls.count)
        self.isDownloading = NO;
    
    if (delegate && [delegate respondsToSelector:@selector(photoDownloader:didDownloadThumbnailForIndex:)]) {
         [delegate photoDownloader:self didDownloadThumbnailForIndex:index];
    }
}

//________________________________________________________________________________________
- (void) parserDidFinish : (CernMediaMARCParser *) parser
{
   //We start downloading images here.
   if (delegate && [delegate respondsToSelector : @selector(photoDownloaderDidFinish:)])
      [delegate photoDownloaderDidFinish : self];
}

//________________________________________________________________________________________
- (void) parser : (CernMediaMARCParser *) parser didFailWithError : (NSError *) error
{
   if (self.delegate && [self.delegate respondsToSelector : @selector(photoDownloader : didFailWithError:)])
      [self.delegate photoDownloader : self didFailWithError : error];
}

@end
