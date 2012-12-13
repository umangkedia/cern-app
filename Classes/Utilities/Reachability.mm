/*
 
 File: Reachability.m
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 
 Version: 2.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/

//Converted into Objective-C++ by Timur Pocheptsov.

#import <cassert>

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>

#import "Reachability.h"

#define kShouldPrintReachabilityFlags 0

namespace CernAPP {

NSString * const reachabilityChangedNotification = @"kNetworkReachabilityChangedNotification";

}

extern "C" {

//________________________________________________________________________________________
void CernAPP_ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
	#pragma unused (target, flags)
   
   assert(info != nullptr && "CernAPP_ReachabilityCallback, parameter 'info' is null");
	assert([(__bridge NSObject*) info isKindOfClass: [Reachability class]] &&
          "CernAPP_ReachabilityCallback, parameter 'info' has wrong type");

	//We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
	// in case someon uses the Reachablity object in a different thread.
	@autoreleasepool {
      Reachability *noteObject = (__bridge Reachability*) info;
      // Post a notification to notify the client that the network reachability changed.
      [[NSNotificationCenter defaultCenter] postNotificationName: CernAPP::reachabilityChangedNotification object: noteObject];
   }
}

}

namespace {

//________________________________________________________________________________________
void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char *comment)
{
#if kShouldPrintReachabilityFlags
	assert(comment != 0 && "PrintReachabilityFlags, parameter 'comment' is null");
   NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
         (flags & kSCNetworkReachabilityFlagsIsWWAN)				  ? 'W' : '-',
         (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',

         (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
         (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
         (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
         (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
         (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
         (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
         comment
        );
#endif
}

}


@implementation Reachability {
	BOOL localWiFiRef;
	SCNetworkReachabilityRef reachabilityRef;
}

//________________________________________________________________________________________
- (BOOL) startNotifier
{
	SCNetworkReachabilityContext	context = {0, (__bridge void *)self, 0, 0, 0};
	if (SCNetworkReachabilitySetCallback(reachabilityRef, CernAPP_ReachabilityCallback, &context) &&
		 SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
      return YES;

	return NO;
}

//________________________________________________________________________________________
- (void) stopNotifier
{
   if (reachabilityRef)
      SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

//________________________________________________________________________________________
- (void) dealloc
{
	[self stopNotifier];
	if (reachabilityRef)
		CFRelease(reachabilityRef);
}

//________________________________________________________________________________________
+ (Reachability *) reachabilityWithHostName : (NSString*) hostName
{
	Reachability *retVal = nil;
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(0, [hostName UTF8String]);
	if (reachability) {
		if ((retVal = [[Reachability alloc] init])) {
			retVal->reachabilityRef = reachability;
			retVal->localWiFiRef = NO;
		}
	}

	return retVal;
}

//________________________________________________________________________________________
+ (Reachability*) reachabilityWithAddress : (const sockaddr_in*) hostAddress
{
	Reachability *retVal = nil;
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const sockaddr*)hostAddress);
	if (reachability) {
		if((retVal = [[Reachability alloc] init])) {
			retVal->reachabilityRef = reachability;
			retVal->localWiFiRef = NO;
		}
	}

	return retVal;
}

//________________________________________________________________________________________
+ (Reachability*) reachabilityForInternetConnection;
{
   sockaddr_in zeroAddress = {};
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;

	return [self reachabilityWithAddress : &zeroAddress];
}

//________________________________________________________________________________________
+ (Reachability*) reachabilityForLocalWiFi;
{
	sockaddr_in localWifiAddress = {};
	localWifiAddress.sin_len = sizeof(localWifiAddress);
	localWifiAddress.sin_family = AF_INET;
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
	Reachability *retVal = [self reachabilityWithAddress : &localWifiAddress];
	if (retVal)
		retVal->localWiFiRef = YES;

	return retVal;
}

#pragma mark Network Flag Handling

using CernAPP::NetworkStatus;

//________________________________________________________________________________________
- (NetworkStatus) localWiFiStatusForFlags : (SCNetworkReachabilityFlags) flags
{
	PrintReachabilityFlags(flags, "localWiFiStatusForFlags");

   NetworkStatus retVal = NetworkStatus::notReachable;

	if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect))
		retVal = NetworkStatus::reachableViaWiFi;

	return retVal;
}

//________________________________________________________________________________________
- (NetworkStatus) networkStatusForFlags : (SCNetworkReachabilityFlags) flags
{
	PrintReachabilityFlags(flags, "networkStatusForFlags");

	if (!(flags & kSCNetworkReachabilityFlagsReachable)) {
		// if target host is not reachable
		return NetworkStatus::notReachable;
	}

   NetworkStatus retVal = NetworkStatus::notReachable;
	
	if (!(flags & kSCNetworkReachabilityFlagsConnectionRequired)) {
		// if target host is reachable and no connection is required
		//  then we'll assume (for now) that your on Wi-Fi
		retVal = NetworkStatus::reachableViaWiFi;
	}
	
	if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)) {
      // ... and the connection is on-demand (or on-traffic) if the
      //     calling application is using the CFSocketStream or higher APIs
      if (!(flags & kSCNetworkReachabilityFlagsInterventionRequired)) {
         // ... and no [user] intervention is needed
         retVal = NetworkStatus::reachableViaWiFi;
      }
   }
	
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
      // ... but WWAN connections are OK if the calling application
      //     is using the CFNetwork (CFSocketStream?) APIs.
      retVal = NetworkStatus::reachableViaWWAN;
	}
   
	return retVal;
}

//________________________________________________________________________________________
- (BOOL) connectionRequired
{
	assert(reachabilityRef != nullptr && "connectionRequired called with NULL reachabilityRef");
   
	SCNetworkReachabilityFlags flags = {};//hehehe, nice C++11.
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
		return flags & kSCNetworkReachabilityFlagsConnectionRequired;

	return NO;
}

//________________________________________________________________________________________
- (NetworkStatus) currentReachabilityStatus
{
   assert(reachabilityRef != nullptr && "currentNetworkStatus called with null reachabilityRef");

	NetworkStatus retVal = NetworkStatus::notReachable;
	SCNetworkReachabilityFlags flags = {};
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		if (localWiFiRef)
			retVal = [self localWiFiStatusForFlags : flags];
		else
			retVal = [self networkStatusForFlags : flags];
	}

	return retVal;
}
@end
