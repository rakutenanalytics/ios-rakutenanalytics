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

NSURL *_RSDKAnalyticsEndpointAddress(void)
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

NSBundle *_RSDKAnalyticsAssetsBundle(void)
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

NSDictionary *_RSDKAnalyticsSDKComponentMap(void)
{
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      NSBundle *bundle = _RSDKAnalyticsAssetsBundle();
                      NSString *filePath = [bundle pathForResource:@"REMModulesMap" ofType:@"plist"];
                      map = [[NSDictionary alloc] initWithContentsOfFile:filePath];
                  });
    return map;
}

NSString *_RSDKAnalyticsStringWithObject(id object)
{
    if (![object isKindOfClass:NSString.class])
    {
        if ([object isKindOfClass:NSNull.class])
        {
            return nil;
        }
        else if ([object respondsToSelector:@selector(stringValue)])
        {
            object = [object stringValue];
        }
        else if (object)
        {
            [NSException raise:NSInvalidArgumentException format:@"Cannot be coerced to a NSString: %@", object];
            object = nil;
        }
    }

    return [object length] ? object : nil;
}

void _RSDKAnalyticsTraverseObjectWithSearchKeys(id object, NSArray *searchKeys, NSMutableDictionary *result)
{
    if ([object isKindOfClass:[NSDictionary class]])
    {
        for (NSString *key in searchKeys)
        {
            if ([object objectForKey:key])
            {
                [result setObject:[object objectForKey:key] forKey:key];
            }
        }
        for (id child in [object allObjects])
        {
            _RSDKAnalyticsTraverseObjectWithSearchKeys(child, searchKeys, result);
        }
    }
    else if ([object isKindOfClass:[NSArray class]])
    {
        for (id child in object)
        {
            _RSDKAnalyticsTraverseObjectWithSearchKeys(child, searchKeys, result);
        }
    }
}
