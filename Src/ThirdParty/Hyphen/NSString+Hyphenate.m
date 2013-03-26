//
//  NSString+Hyphenate.m
//
//  Created by Eelco Lempsink on 09-06-10.
//  Copyright 2010 Tupil. All rights reserved.
//

#import "NSString+Hyphenate.h"

#include "hyphen.h"

@implementation NSString (Hyphenate)

//________________________________________________________________________________________
- (NSString*) stringByHyphenatingWithLocale : (NSLocale*) locale
{
   static HyphenDict* dict = NULL;
   static NSString* localeIdentifier = nil;
   
   ////////////////////////////////////////////////////////////////////////////
   // Setup.
   //
   // Establish that we got all the information we need: the bundle with 
   // dictionaries, the locale and the loaded dictionary.  Cache dictionary and
   // save the language code used to retrieve it.
   //

   // Try to guess the locale from the string, if not given.
   CFStringRef language;
   if (!locale && (language = CFStringTokenizerCopyBestStringLanguage((CFStringRef)self, CFRangeMake(0, [self length])))) {
      locale = [[NSLocale alloc] initWithLocaleIdentifier : (__bridge NSString*)language];
      CFRelease(language);                
   }
   
   if (!locale) {
      return self;
   } // else
   
   if (![localeIdentifier isEqualToString : [locale localeIdentifier]] && dict) {
      hnj_hyphen_free(dict);
      dict = 0;
   }
   
   localeIdentifier = [locale localeIdentifier];

   if (!dict)
      dict = hnj_hyphen_load([[[NSBundle mainBundle] pathForResource : [NSString stringWithFormat : @"hyph_%@", localeIdentifier] ofType : @"dic"] UTF8String]);

    
   if (!dict)
      return self;

   ////////////////////////////////////////////////////////////////////////////
   // The works.
   //
   // No turning back now.  We traverse the string using a tokenizer and pass
   // every word we find into the hyphenation function.  Non-used tokens and
   // hyphenated words will be appended to the result string.
   //
   
   NSMutableString * const result = [NSMutableString stringWithCapacity : [self length] * 1.2];
   
   // Varibles used for tokenizing
   
   CFStringTokenizerTokenType tokenType;
   CFRange tokenRange;
   NSString* token;
   
   // Varibles used for hyphenation
   char* hyphens;
   char** rep;
   int* pos;
   int* cut;
   int wordLength;
   int i;
   
   CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, (CFStringRef)self, CFRangeMake(0, [self length]),
                                                            kCFStringTokenizerUnitWordBoundary, (CFLocaleRef)locale);
    
   while ((tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)) != kCFStringTokenizerTokenNone) {
      tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
      token = [self substringWithRange : NSMakeRange(tokenRange.location, tokenRange.length)];

      if (tokenType & kCFStringTokenizerTokenHasNonLettersMask) {
         [result appendString:token];
      } else {
         char const *tokenChars = [[token lowercaseString] UTF8String];
         wordLength = strlen(tokenChars);
         // This is the buffer size the algorithm needs.
         hyphens = (char*)malloc(wordLength + 5); // +5, see hypen.h
         rep = 0; // Will be allocated by the algorithm
         pos = 0; // Idem
         cut = 0; // Idem

         // rep, pos and cut are not currently used, but the simpler
         // hyphenation function is deprecated.
         hnj_hyphen_hyphenate2(dict, tokenChars, wordLength, hyphens, 0, &rep, &pos, &cut);

         NSUInteger loc = 0;
         NSUInteger len = 0;

         for (i = 0; i < wordLength; i++) {
            if (hyphens[i] & 1) {
               len = i - loc + 1;
               [result appendString : [token substringWithRange : NSMakeRange(loc, len)]];
               [result appendString : @"­"]; // NOTE: UTF-8 soft hyphen!
               loc = loc + len;
            }
         }
         
         if (loc < wordLength)
            [result appendString : [token substringWithRange : NSMakeRange(loc, wordLength - loc)]];

         // Clean up
         free(hyphens);

         if (rep) {
            for (i = 0; i < wordLength; i++) {
               if (rep[i]) free(rep[i]);
            }
            free(rep);
            free(pos);
            free(cut);
         }
      }
   }
   
   CFRelease(tokenizer);
   
   return result;
}

@end
