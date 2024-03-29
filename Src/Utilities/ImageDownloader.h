#import <Foundation/Foundation.h>

//
//Small and trivial class - wrapper for a NSURLConnection to
//download images (thumbnails and icons). Inspired by Apple's
//LazyTableImages code sample.
//

@protocol ImageDownloaderDelegate
@required
- (void) imageDidLoad : (NSIndexPath *) indexPath;
- (void) imageDownloadFailed : (NSIndexPath *) indexPath;
@end


@interface ImageDownloader : NSObject<NSURLConnectionDelegate>

- (id) initWithURLString : (NSString *) url;
- (id) initWithURL : (NSURL *) url;
- (void) startDownload;
- (void) cancelDownload;

@property (weak) NSObject<ImageDownloaderDelegate> * delegate;

@property (nonatomic, strong) NSIndexPath *indexPathInTableView;
@property (nonatomic, strong) UIImage *image;

@end
