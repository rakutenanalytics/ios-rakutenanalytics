#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RMoriType) {
    RMoriTypePortrait = 1,
    RMoriTypeLandscape = 2
};

@interface _RStatusBarOrientationHandler : NSObject

/**
 * Retrieve the mori value based on status bar orientation
 *
 * @return The mori value (RMoriTypePortrait or RMoriTypeLandscape)
 */
- (RMoriType)mori;

@end

NS_ASSUME_NONNULL_END
