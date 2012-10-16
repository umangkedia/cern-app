//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows author, title, short content, date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

#import <UIKit/UIKit.h>

#import "RSSGridViewController.h"

@interface NewsTableViewController : RSSTableViewController

@property NSRange rangeOfArticlesToShow;

@end
