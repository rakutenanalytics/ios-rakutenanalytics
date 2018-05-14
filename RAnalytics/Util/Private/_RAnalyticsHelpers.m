#import <RAnalytics/RAnalyticsManager.h>
#import "_RAnalyticsHelpers.h"

BOOL _RAnalyticsObjectsEqual(id objA, id objB)
{
    return (!objA && !objB) || (objA && objB && [objA isEqual:objB]);
}

NSURL *_RAnalyticsEndpointAddress(void)
{
    NSString *plistObj = [NSBundle.mainBundle objectForInfoDictionaryKey:@"RATEndpoint"];
    
    NSURL* userRATURL = plistObj.length != 0 ? [NSURL URLWithString:plistObj] : nil;
    NSURL* RAEProductionURL = [NSURL URLWithString:@"https://rat.rakuten.co.jp/"];
    NSURL* RAEStagingURL    = [NSURL URLWithString:@"https://stg.rat.rakuten.co.jp/"];
    
    if (userRATURL) {
        return userRATURL;
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    BOOL useStaging = [RAnalyticsManager sharedInstance].shouldUseStagingEnvironment;
    #pragma clang diagnostic pop
    return useStaging ? RAEStagingURL : RAEProductionURL;
    
}

NSBundle *_RAnalyticsAssetsBundle(void)
{
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      // Can't use [NSBundle mainBundle] here, because it returns the path to XCTest.framework
                      // when running unit tests. Also, if the SDK is being bundled as a dynamic framework,
                      // then it comes in its own bundle.
                      NSBundle *classBundle = [NSBundle bundleForClass:[RAnalyticsManager class]];

                      // If RAnalyticsAssets.bundle cannot be found, we revert to using the class bundle
                      NSString *assetsPath = [classBundle.resourcePath stringByAppendingPathComponent:@"RAnalyticsAssets.bundle"];
                      bundle = [NSBundle bundleWithPath:assetsPath] ?: classBundle;
                  });
    return bundle;
}

NSDictionary *_RAnalyticsSDKComponentMap(void)
{
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      NSBundle *bundle = _RAnalyticsAssetsBundle();
                      NSString *filePath = [bundle pathForResource:@"REMModulesMap" ofType:@"plist"];
                      map = [[NSDictionary alloc] initWithContentsOfFile:filePath];
                  });
    return map;
}

