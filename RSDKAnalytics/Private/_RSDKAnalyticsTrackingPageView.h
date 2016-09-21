/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */

#import <objc/runtime.h>
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

// ViewDidAppear event
/*
 * Event triggered when the view is shown. This private event is collected by _RSDKAnalyticsLaunchCollector
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventViewDidAppear;

@interface _RSDKAnalyticsSwizzleBaseClass : NSObject
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
@interface _RSDKAnalyticsTrackingPageView : _RSDKAnalyticsSwizzleBaseClass<UIApplicationDelegate>
@end
