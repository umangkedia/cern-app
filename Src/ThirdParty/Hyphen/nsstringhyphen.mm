#import <cstddef>
#import <cassert>
#import <vector>

#import "nsstringhyphen.h"

namespace {

//________________________________________________________________________________________
NSLocale *GuessLocaleFromNSString(NSString *text)
{
   assert(text != nil && "GuessLocaleFromNSString, parameter 'text' is nil");
   
   NSLocale *locale = nil;
   const CFRange range = CFRangeMake(0, text.length);
   if (CFStringRef language = CFStringTokenizerCopyBestStringLanguage((__bridge CFStringRef)text, range)) {
      locale = [[NSLocale alloc] initWithLocaleIdentifier : (__bridge NSString*)language];
      CFRelease(language);
   }

   return locale;
}

}

namespace CernAPP {

//________________________________________________________________________________________
HyphenDict *CreateHyphenationDictionary(NSLocale *locale, NSString *text)
{
   assert(locale != nil || text != nil &&
          "CreateHyphenationDictionary, both 'locale' and 'text' parameters are nil");
   
   if (!locale && !(locale = GuessLocaleFromNSString(text)))
      return nullptr;
   
   NSString * const localeIdentifier = [locale localeIdentifier];
   return hnj_hyphen_load([[[NSBundle mainBundle] pathForResource : [NSString stringWithFormat : @"hyph_%@", localeIdentifier] ofType : @"dic"] UTF8String]);
}

//Locale can be nil (source will be used to guess the locale), both
//dictionary and source are non-nil.
//________________________________________________________________________________________
NSString *HyphenateNSString(NSLocale *locale, const HyphenDict *dictionary, NSString *source)
{
   assert(dictionary != nullptr && "HyphenateNSString, parameter 'dictionary' is null");
   assert(source != nil && "HyphenateNSString, parameter 'source' is nil");
   
   NSMutableString *result = [[NSMutableString alloc] init];
   
   if (!locale && !(locale = GuessLocaleFromNSString(source)))
      return nil;
   
   CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault,
                                                            (__bridge CFStringRef)source, CFRangeMake(0, source.length),
                                                            kCFStringTokenizerUnitWordBoundary,
                                                            (__bridge CFLocaleRef)locale);
   
   if (!tokenizer)
      return nil;

   std::vector<char> hyphens;
   CFStringTokenizerTokenType tokenType = kCFStringTokenizerTokenNone;
   char **rep = 0;
   int *pos = 0;
   int *cut = 0;
   
   while ((tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)) != kCFStringTokenizerTokenNone) {
      const CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
      NSString * const token = [source substringWithRange : NSMakeRange(tokenRange.location, tokenRange.length)];
      if (tokenType & kCFStringTokenizerTokenHasNonLettersMask) {
         [result appendString : token];
      } else {
         NSString * const lcToken = [token lowercaseString];
         char const *tokenChars = [lcToken UTF8String];//null-terminated string.
         const int wordLength = (int)[lcToken lengthOfBytesUsingEncoding : NSUTF8StringEncoding];
         // This is the buffer size the algorithm needs.
         hyphens.assign(wordLength + 5, 0); //// +5, see hypen.h
         rep = 0;
         pos = 0;
         cut = 0;

         // rep, pos and cut are not currently used, but the simpler
         // hyphenation function is deprecated.
         const int rez = hnj_hyphen_hyphenate2((HyphenDict *)dictionary, tokenChars, wordLength - 1, &hyphens[0], 0, &rep, &pos, &cut);

         if (!rez) {
            //Now we have to somehow compose the new string with 'soft' hyphens.
            //Do some magic here!
         }

         if (rep) {
            for (std::size_t i = 0; i < wordLength; ++i)
               free(rep[i]);
         }

         free(rep);
         free(pos);
         free(cut);
         
         if (rez) {
            result = nil;
            break;
         }
      }
   }
   
   CFRelease(tokenizer);

   return result;
}

}
