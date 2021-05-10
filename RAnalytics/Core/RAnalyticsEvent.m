#import "RAnalyticsEvent.h"

// Standard event names
NSString *const RAnalyticsInitialLaunchEventName         = @"_rem_init_launch";
NSString *const RAnalyticsSessionStartEventName          = @"_rem_launch";
NSString *const RAnalyticsSessionEndEventName            = @"_rem_end_session";
NSString *const RAnalyticsApplicationUpdateEventName     = @"_rem_update";
NSString *const RAnalyticsLoginEventName                 = @"_rem_login";
NSString *const RAnalyticsLoginFailureEventName          = @"_rem_login_failure";
NSString *const RAnalyticsLogoutEventName                = @"_rem_logout";
NSString *const RAnalyticsInstallEventName               = @"_rem_install";
NSString *const RAnalyticsPageVisitEventName             = @"_rem_visit";
NSString *const RAnalyticsPushNotificationEventName      = @"_rem_push_notify";
NSString *const RAnalyticsSSOCredentialFoundEventName    = @"_rem_sso_credential_found";
NSString *const RAnalyticsLoginCredentialFoundEventName  = @"_rem_login_credential_found";
NSString *const RAnalyticsCredentialStrategiesEventName  = @"_rem_credential_strategies";

// Custom event name
NSString *const RAnalyticsCustomEventName                = @"_analytics_custom";

// Standard event parameters
NSString *const RAnalyticsLogoutMethodEventParameter                    = @"logout_method";
NSString *const RAnalyticsPushNotificationTrackingIdentifierParameter    = @"tracking_id";

// Custom event parameters
NSString *const RAnalyticsCustomEventNameParameter                    = @"eventName";
NSString *const RAnalyticsCustomEventDataParameter                    = @"eventData";
NSString *const RAnalyticsCustomEventTopLevelObjectParameter          = @"topLevelObject";

// Standard event parameter values
NSString *const RAnalyticsLocalLogoutMethod          = @"local";
NSString *const RAnalyticsGlobalLogoutMethod         = @"global";
