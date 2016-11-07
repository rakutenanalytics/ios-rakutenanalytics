/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

RSDKA_EXPORT @interface _RSDKAnalyticsClassManipulator : NSObject
/*
 * Add a new method to a class, optionally replacing an existing one.
 *
 * @param newSelector       Selector of the current class' method to add to the recipient class.
 * @param recipient         Recipient class
 * @param originalSelector  Selector naming the method on the recipient class. If the selector already
 *                          exists, that original method will be swapped for the new one.
 * @param onlyIfPresent     If `originalSelector` is not found on the recipient class, the method does
 *                          nothing and returns `NO`.
 * @return Whether or not the method was added to the recipient class.
 */
+ (BOOL)addMethodWithSelector:(SEL)newSelector
                      toClass:(Class)recipient
                    replacing:(SEL)originalSelector
                onlyIfPresent:(BOOL)onlyIfPresent;
@end

NS_ASSUME_NONNULL_END
