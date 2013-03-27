#import <cstddef>
#import <cassert>
#import <vector>

#import "nsstringhyphen.h"

//
//This code is a total mess and I'm simply not using it at the moment.
//TODO: may be later I'll try to revive it.
//

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
   
   //I have a really bad feeling about this :) It looks like a crap :) TODO: fix it!
   static NSString * const softHyphen = [NSString stringWithFormat : @"%C", (unsigned short)0xad];
   
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
         char const *lcTokenChars = [lcToken UTF8String];//null-terminated string.
         const NSUInteger wordLength = [lcToken lengthOfBytesUsingEncoding : NSUTF8StringEncoding];
         
         if (!wordLength)
            continue;
         
         // This is the buffer size the algorithm needs.
         hyphens.assign(wordLength + 5, 0); //// +5, see hypen.h
         rep = 0;
         pos = 0;
         cut = 0;

         // rep, pos and cut are not currently used, but the simpler
         // hyphenation function is deprecated.
         const int rez = hnj_hyphen_hyphenate2((HyphenDict *)dictionary, lcTokenChars, (int)wordLength - 1, &hyphens[0], 0, &rep, &pos, &cut);
         
         if (rez) {
            [result appendString : token];
         } else {
            //Now we have to somehow compose the new string with 'soft' hyphens.
            //Do some magic here!

            //Let's test hyphenation.
            if (result.length)
               [result appendString : @" "];

            const char *tokenChars = [token UTF8String];
            NSUInteger start = 0;
            for (NSUInteger i = 0; i < wordLength; ++i) {
               if (hyphens[i] & 1) {
                  NSString * const substring =  [[NSString alloc] initWithBytes : tokenChars + start length : i - start + 1 encoding : NSUTF8StringEncoding];
                  if (!substring) {
                     [result appendString : token];
                     start = wordLength;
                     break;
                  }

                  [result appendString : substring];
                  [result appendString : softHyphen];
                  
                  start = i + 1;
               }
            }
            
            if (start < wordLength)
               [result appendString : [[NSString alloc] initWithBytes : tokenChars + start length : wordLength - start encoding : NSUTF8StringEncoding]];
         }

         if (rep) {
            for (std::size_t i = 0; i < wordLength; ++i)
               free(rep[i]);
         }

         free(rep);
         free(pos);
         free(cut);
      }
   }
   
   CFRelease(tokenizer);

   return result;
}

}
