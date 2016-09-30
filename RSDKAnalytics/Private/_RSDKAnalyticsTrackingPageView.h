/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */

#import <objc/runtime.h>
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

RSDKA_EXPORT @interface _RSDKAnalyticsSwizzleBaseClass : NSObject
+ (void)swizzleSelector:(SEL)swizzleSelector targetSelector:(SEL)targetSelector class:(Class)class;
@end

/*
 * This class is for swizzling some UIApplicationDelegate's methods such as 
 * application:didFinishLaunchingWithOptions:, 
 * application:openURL:options:, 
 * application:continueUserActivity:restorationHandler:, 
 * application:handleActionWithIdentifier:forRemoteNotification:completionHandler: 
 * and UIViewController's viewDidAppear:.
 */
RSDKA_EXPORT @interface _RSDKAnalyticsTrackingPageView : _RSDKAnalyticsSwizzleBaseClass<UIApplicationDelegate>
@end
