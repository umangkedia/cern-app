#import <Foundation/Foundation.h>

#import "hyphen.h"

namespace CernAPP {

//Either locale, or text can be nil, but not both.
//text is used only if locale is nil (I'm trying to guess the locale).
HyphenDict *CreateHyphenationDictionary(NSLocale *locale, NSString *text);
//Locale can be nil (source will be used to guess the locale), both
//dictionary and source are non-nil.
NSString *HyphenateNSString(NSLocale *locale, const HyphenDict *dictionary, NSString *source);

}
