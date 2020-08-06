
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@interface UNNotification (Trackable)

+ (nullable NSString*)trackingIdentifierFromPayload: (NSDictionary*) payload;

@end

NS_ASSUME_NONNULL_END
