#import <Foundation/Foundation.h>

namespace CernAPP {

NSArray *ReadFeedCache(NSString *feedStoreID);
void WriteFeedCache(NSString *feedStoreID, NSArray *feedCache, NSArray *allArticles);

}