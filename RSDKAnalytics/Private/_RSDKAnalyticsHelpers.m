/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsHelpers.h"
#import <RSDKAnalytics/RSDKAnalyticsManager.h>

BOOL _RSDKAnalyticsObjects_equal(id objA, id objB)
{
    return (!objA && !objB) || (objA && objB && [objA isEqual:objB]);
}

NSURL *_RSDKAnalyticsEndpointAddress()
{
    static NSURL *productionURL, *stagingURL;
    static dispatch_once_t once;
    dispatch_once(&once, ^
                  {
                      productionURL = [NSURL URLWithString:@"https://rat.rakuten.co.jp/"];
                      stagingURL    = [NSURL URLWithString:@"https://stg.rat.rakuten.co.jp/"];
                  });
    BOOL useStaging = [RSDKAnalyticsManager sharedInstance].shouldUseStagingEnvironment;
    return useStaging ? stagingURL : productionURL;
}

NSBundle *_RSDKAnalyticsAssetsBundle()
{
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      // Can't use [NSBundle mainBundle] here, because it returns the path to XCTest.framework
                      // when running unit tests. Also, if the SDK is being bundled as a dynamic framework,
                      // then it comes in its own bundle.
                      NSBundle *classBundle = [NSBundle bundleForClass:[RSDKAnalyticsManager class]];

                      // If RSDKAnalyticsAssets.bundle cannot be found, we revert to using the class bundle
                      NSString *assetsPath = [classBundle.resourcePath stringByAppendingPathComponent:@"RSDKAnalyticsAssets.bundle"];
                      bundle = [NSBundle bundleWithPath:assetsPath] ?: classBundle;
                  });
    return bundle;
}

NSDictionary *_RSDKAnalyticsSDKComponentMap()
{
    NSBundle *bundle = _RSDKAnalyticsAssetsBundle();
    NSString *filePath = [bundle pathForResource:@"_RSDKAnalyticsREMModules" ofType:@"plist"];
    return [[NSDictionary alloc] initWithContentsOfFile:filePath];
}
