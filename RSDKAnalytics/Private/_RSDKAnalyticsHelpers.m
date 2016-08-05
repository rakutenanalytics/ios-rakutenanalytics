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