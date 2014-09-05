//
//  UIResponder+RErrorResponder.h
//  RSDKSupport
//
//  Created by Zachary Radke on 1/3/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

@import UIKit;

/**
 * Allow presentation of `NSError` recovery options. This takes advantage of the responder chain to present errors, and will walk the chain until a `UIResponder` subclasss actively presents the error and halts the chain. This somewhat models the error handling behavior of AppKit. Since `UIApplication`, `UIView` and `UIViewController` are all subclasses of `UIResponder`, error presentation can be done from virtually any UI object, and customized accordingly.
 *
 * @category UIResponder(RErrorResponder) UIResponder+RErrorResponder.h <RSDKSupport/UIResponder+RErrorResponder.h>
 */
@interface UIResponder (RErrorResponder)

/**
 * Present an error to the user. This base category simply walks up the responder chain. Subclasses of `UIResponder` should override this method if they want to customize the error presentation, otherwise it should trickle down to @ref UIApplication(RErrorResponder)'s implementation of this method.
 *
 *  @param error             The error to present. If `nil`, this method does nothing.
 *  @param completionHandler An optional completion handler invoked when the user finishes choosing an action.
 */
- (void)r_presentError:(NSError *)error completionHandler:(void (^)(BOOL didRecover))completionHandler;

#if RSDKSupportShorthand

/**
 *  An alias of #r_presentError:completionHandler:
 *
 * @note This method is only available if #RSDKSupportShorthand has been defined.
 *
 *  @param error             The error to present. If `nil`, this method does nothing.
 *  @param completionHandler An optional completion handler invoked when the user finishes choosing an action.
 */
- (void)presentError:(NSError *)error completionHandler:(void (^)(BOOL didRecover))completionHandler;

#endif

@end


/**
 * Category which overrides methods defined in the @ref UIResponder(RErrorResponder) to concretely present `NSError` instances in a `UIAlertView`. Since `UIApplication` typically acts as the last link in the responder chain, this behavior will only be used if no other responders in the chain override the necessary method, or if the responder in question has been removed from the primary chain.
 *
 * @category UIApplication(RErrorResponder) UIResponder+RErrorResponder.h <RSDKSupport/UIResponder+RErrorResponder.h>
 */
@interface UIApplication (RErrorResponder)

/**
 * Present an alert using the error's localized description as the title, the localized recovery suggestion as the message, and the localized recovery options as buttons. When recovery options and a recovery manager are present, the recovery manager will be used with the button index selected by the user. In the absense of recovery options, a single **OK** button is added to allow dismissal of the alert view. This is a concrete implementation of the method defined in @ref UIResponder(RErrorResponder).
 *
 *  @param error             The error to present. If `nil`, this method does nothing.
 *  @param completionHandler An optional completion handler invoked when the user finishes choosing an action.
 */
- (void)r_presentError:(NSError *)error completionHandler:(void (^)(BOOL didRecover))completionHandler;

@end
