//
//  UIResponder+RErrorResponder.m
//  RSDKSupport
//
//  Created by Zachary Radke on 1/3/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

@import ObjectiveC.runtime;

#import "UIResponder+RErrorResponder.h"

static void *kRErrorResponderAlertViewDelegateKey = &kRErrorResponderAlertViewDelegateKey;

@interface _RErrorResponderAlertViewDelegate : NSObject <UIAlertViewDelegate>

@property (strong, nonatomic) NSError *error;
@property (copy, nonatomic) void (^completionHandler)(BOOL);

@end

@implementation _RErrorResponderAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    BOOL didRecover = [[self.error recoveryAttempter] attemptRecoveryFromError:self.error optionIndex:buttonIndex];
    
    if (self.completionHandler)
    {
        self.completionHandler(didRecover);
    }
    
    // Make sure to unset the delegate before we allow this instance to be deallocated, since delegates are now unsafe
    [alertView setDelegate:nil];
    
    // Clear the strong reference we make between the delegate and the alert view, allowing this instance to be deallocated
    objc_setAssociatedObject(alertView, kRErrorResponderAlertViewDelegateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIResponder (RErrorResponder)

- (void)r_presentError:(NSError *)error completionHandler:(void (^)(BOOL))completionHandler
{
    if (!error) { return; }
    
    if (self.nextResponder)
    {
        [self.nextResponder r_presentError:error completionHandler:completionHandler];
    }
}

#if RSDKSupportShorthand

- (void)presentError:(NSError *)error completionHandler:(void (^)(BOOL))completionHandler
{
    [self r_presentError:error completionHandler:completionHandler];
}

#endif

@end

@implementation UIApplication (RErrorResponder)

- (void)r_presentError:(NSError *)error completionHandler:(void (^)(BOOL))completionHandler
{
    if (!error) { return; }
    
    _RErrorResponderAlertViewDelegate *delegate = [_RErrorResponderAlertViewDelegate new];
    delegate.error = error;
    delegate.completionHandler = completionHandler;
    
    NSString *title = error.userInfo[NSLocalizedDescriptionKey];
    NSString *message = error.userInfo[NSLocalizedFailureReasonErrorKey];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:nil otherButtonTitles:nil];
    
    NSArray *recoveryOptions = [error localizedRecoveryOptions];
    if (!recoveryOptions || recoveryOptions.count == 0)
    {
        // By default always include at least a single button so the alert view can be dismissed
        [alertView addButtonWithTitle:@"Ok"];
    } else
    {
        for (NSString *optionTitle in recoveryOptions)
        {
            [alertView addButtonWithTitle:optionTitle];
        }
    }
    
    // Strongly reference the delegate to the alert view so we don't have to maintain and clean the instance
    objc_setAssociatedObject(alertView, kRErrorResponderAlertViewDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [alertView show];
}

@end
