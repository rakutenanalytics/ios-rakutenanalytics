#import "_RStatusBarOrientationHandler.h"
#import "UIApplication+Additions.h"

@interface _RStatusBarOrientationHandler()
@property (nonatomic) UIInterfaceOrientation currentStatusBarOrientation;
@end

@implementation _RStatusBarOrientationHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([UIApplication _rat_respondsToSharedApplication]) {
            _currentStatusBarOrientation = [UIApplication _rat_statusBarOrientation];
            
            // UIApplicationWillChangeStatusBarOrientationNotification is preferred to UIApplicationDidChangeStatusBarOrientationNotification in order to get the correct statusBarOrientation value before the payload is built with mori key where statusBarOrientation is set
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSNumber *result = [note.userInfo objectForKey:UIApplicationStatusBarOrientationUserInfoKey];
                    if (result) {
                        self.currentStatusBarOrientation = [result intValue];
                    }
                });
            }];
            
        } else { // [UIApplication sharedApplication] is not available for App Extension
            _currentStatusBarOrientation = UIInterfaceOrientationPortrait; // default value
        }
    }
    return self;
}

- (RMoriType)mori
{
    return (UIInterfaceOrientationIsLandscape(self.currentStatusBarOrientation) ? RMoriTypeLandscape : RMoriTypePortrait);
}

@end
