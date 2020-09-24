#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@interface _RLogger : NSObject

/**
 * The current logging level.
 */
@property (class, nonatomic, assign) RLoggingLevel loggingLevel;

/**
 * Log a verbose message.
 *
 * @param format The formatted message to be logged
 *
 * @return The printed message.
 */
+ (NSString * _Nullable )verbose:(NSString *)format, ...;

/**
 * Log a debug message.
 *
 * @param format The formatted message to be logged
 *
 * @return The printed message.
 */
+ (NSString * _Nullable )debug:(NSString *)format, ...;

/**
 * Log an info message.
 *
 * @param format The formatted message to be logged
 *
 * @return The printed message.
 */
+ (NSString * _Nullable )info:(NSString *)format, ...;

/**
 * Log a warning message.
 *
 * @param format The formatted message to be logged
 *
 * @return The printed message.
 */
+ (NSString * _Nullable )warning:(NSString *)format, ...;

/**
 * Log an error message.
 *
 * @param format The formatted message to be logged
 *
 * @return The printed message.
 */
+ (NSString * _Nullable )error:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
