/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "AppDelegate.h"

@implementation AppDelegate
@synthesize window;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
}
#pragma clang diagnostic pop

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
}

@end
