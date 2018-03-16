#import <objc/runtime.h>
#import "_RAnalyticsClassManipulator.h"

@implementation _RAnalyticsClassManipulator
+ (BOOL)addMethodWithSelector:(SEL)newSelector
                      toClass:(Class)recipient
                    replacing:(SEL)originalSelector
                onlyIfPresent:(BOOL)onlyIfPresent
{
    NSParameterAssert(newSelector);
    NSParameterAssert(originalSelector);
    if (!recipient) return NO;

    Method newMethod      = class_getInstanceMethod(self,      newSelector);
    Method originalMethod = class_getInstanceMethod(recipient, originalSelector);
    SEL resultSelector    = originalSelector;

    /*
     * If the target method exists, we exchange its implementation with our new one and
     * update originalSelector to still point to the original implementation.
     */
    if (originalMethod)
    {
        method_exchangeImplementations(newMethod, originalMethod);
        resultSelector = newSelector;
    }
    /*
     * If the target method doesn't exist but was required, we don't do anything.
     */
    else if (onlyIfPresent)
    {
        return NO;
    }

    /*
     * If at this point no method exists for the selector, it means that either:
     * - The original method didn't exist, so we need to add the new method in its place; or
     * - The original method was replaced, so we need to add back its original implementation (that now
     *   uses what was passed as `newSelector`).
     */
    if (!class_getInstanceMethod(recipient, resultSelector))
    {
        class_addMethod(recipient,
                        resultSelector,
                        method_getImplementation(newMethod),
                        method_getTypeEncoding(newMethod));
    }

    return YES;
}
@end
