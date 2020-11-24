#import "_RStatusBarOrientationHandler.h"
#import <RAnalytics/RAnalytics-Swift.h>

@interface _RStatusBarOrientationHandler()
@property (nonatomic) UIInterfaceOrientation currentStatusBarOrientation;
@end

@implementation _RStatusBarOrientationHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        // As _RStatusBarOrientationHandler is instantiated from RAnalyticsRATTracker that is instantiated from [RAnalyticsManager load], [[UIApplication sharedApplication]] returns nil.
        // Therefore we need to dispatch this operation in the main queue so [[UIApplication sharedApplication]] is not nil when this operation is executed.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentStatusBarOrientation = [UIApplication ratStatusBarOrientation];
        });
        
        // UIApplicationWillChangeStatusBarOrientationNotification is preferred to UIApplicationDidChangeStatusBarOrientationNotification in order to get the correct statusBarOrientation value before the payload is built with mori key where statusBarOrientation is set
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSNumber *result = [note.userInfo objectForKey:UIApplicationStatusBarOrientationUserInfoKey];
                if (result) {
                    self.currentStatusBarOrientation = [result intValue];
                }
            });
        }];
    }
    return self;
}

- (RMoriType)mori
{
    return (UIInterfaceOrientationIsLandscape(self.currentStatusBarOrientation) ? RMoriTypeLandscape : RMoriTypePortrait);
}

@end
