#import "_RAnalyticsCoreHelpers.h"
#import "_RAnalyticsHelpers.h"

NSString *const _RAnalyticsAppInfoKey = @"_RAnalyticsAppInfoKey";
NSString *const _RAnalyticsSDKInfoKey = @"_RAnalyticsSDKInfoKey";

NSDictionary *_RAnalyticsSharedPayload(RAnalyticsState * state)
{
    static NSString *osVersion;
    static NSString *bundleVersion;
    static NSString *applicationName;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UIDevice *device = UIDevice.currentDevice;
        osVersion = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];
        NSBundle *bundle = NSBundle.mainBundle;
        applicationName = bundle.bundleIdentifier;
        bundleVersion = state.currentVersion;
    });

    NSMutableDictionary *dict = NSMutableDictionary.new;

    // MARK: app_ver
    dict[@"app_ver"] = bundleVersion;

    // MARK: app_name
    dict[@"app_name"] = applicationName;

    // MARK: mos
    dict[@"mos"] = osVersion;

    // MARK: ver
    dict[@"ver"] = RAnalyticsVersion;

    // MARK: ts1
    dict[@"ts1"] = @(MAX(0ll, (int64_t) round(NSDate.date.timeIntervalSince1970)));

    return dict.copy;
}

NSDictionary *_RAnalyticsApplicationInfoAndSDKComponents(void)
{
    static NSDictionary *result;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableDictionary *dict = NSMutableDictionary.new;
        // Collect build environment (Xcode version and build SDK)
        NSDictionary *info = NSBundle.mainBundle.infoDictionary;
        NSString *xcodeVersion = info[@"DTXcode"];
        NSString *xcodeBuild   = info[@"DTXcodeBuild"];
        if (xcodeBuild)
        {
            xcodeVersion = [xcodeVersion stringByAppendingFormat:@".%@", xcodeBuild];
        }

        NSString *buildSDK = info[@"DTSDKName"];
        if (!buildSDK)
        {
            buildSDK = info[@"DTPlatformName"];
            NSString *version = info[@"DTPlatformVersion"];
            if (version)
            {
                buildSDK = [buildSDK stringByAppendingString:version];
            }
        }

        // Collect information on frameworks shipping with the app
        NSDictionary *sdkComponentMap = _RAnalyticsSDKComponentMap();
        NSMutableDictionary *sdkInfo = NSMutableDictionary.new;

        NSMutableDictionary *otherFrameworks = [NSMutableDictionary dictionary];
        for (NSBundle *bundle in NSBundle.allFrameworks)
        {
            NSString *identifier = bundle.bundleIdentifier;

            if (!identifier || [identifier hasPrefix:@"com.apple."]) continue;

            NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            if ([sdkComponentMap objectForKey:identifier])
            {
                sdkInfo[sdkComponentMap[identifier]] = version;
            }
            else
            {
                otherFrameworks[identifier] = version;
            }
        }

        NSMutableDictionary *appInfo = [NSMutableDictionary dictionary];
        if (xcodeVersion.length)       appInfo[@"xcode"] = xcodeVersion;
        if (buildSDK.length)           appInfo[@"sdk"] = buildSDK;
        if (otherFrameworks.count)     appInfo[@"frameworks"] = otherFrameworks;
        if (info[@"MinimumOSVersion"]) appInfo[@"deployment_target"] = info[@"MinimumOSVersion"];

        dict[_RAnalyticsAppInfoKey] = appInfo.copy;
        dict[_RAnalyticsSDKInfoKey] = sdkInfo.copy;
        result = dict.copy;
    });
    return result;
}
