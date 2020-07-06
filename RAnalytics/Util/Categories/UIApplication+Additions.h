#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication(Additions)
+ (BOOL)_rat_respondsToSharedApplication;
+ (UIInterfaceOrientation)_rat_statusBarOrientation;
@end

NS_ASSUME_NONNULL_END
