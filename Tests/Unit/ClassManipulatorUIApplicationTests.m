@import XCTest;
#import <Kiwi/Kiwi.h>
#import <UIKit/UIKit.h>

#pragma mark - Empty AppDelegate

@interface EmptyAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation EmptyAppDelegate
@end

#pragma mark - WillFinishLaunchingWithOptions AppDelegate

@interface WillFinishLaunchingWithOptionsAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation WillFinishLaunchingWithOptionsAppDelegate
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
@end

#pragma mark - DidFinishLaunchingWithOptions AppDelegate

@interface DidFinishLaunchingWithOptionsAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation DidFinishLaunchingWithOptionsAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
@end

#pragma mark - Full AppDelegate

@interface FullAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation FullAppDelegate
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
@end

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(ClassManipulatorUIApplicationTests)

describe(@"_RAnalyticsClassManipulator", ^{
    __block EmptyAppDelegate *emptyAppDelegate;
    __block WillFinishLaunchingWithOptionsAppDelegate *willFinishLaunchingWithOptionsAppDelegate;
    __block DidFinishLaunchingWithOptionsAppDelegate *didFinishLaunchingWithOptionsAppDelegate;
    __block FullAppDelegate *fullAppDelegate;
    
    beforeAll(^{
        emptyAppDelegate = EmptyAppDelegate.new;
        willFinishLaunchingWithOptionsAppDelegate = WillFinishLaunchingWithOptionsAppDelegate.new;
        didFinishLaunchingWithOptionsAppDelegate = DidFinishLaunchingWithOptionsAppDelegate.new;
        fullAppDelegate = FullAppDelegate.new;
    });
    
    describe(@"EmptyAppDelegate", ^{
        it(@"should not respond to _r_autotrack_application launching methods", ^{
            UIApplication *application = UIApplication.sharedApplication;
            application.delegate = emptyAppDelegate;
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beFalse];
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beFalse];
        });
    });
    
    describe(@"WillFinishLaunchingWithOptionsAppDelegate", ^{
        it(@"should respond to _r_autotrack_application:willFinishLaunchingWithOptions:", ^{
            UIApplication *application = UIApplication.sharedApplication;
            application.delegate = willFinishLaunchingWithOptionsAppDelegate;
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beFalse];
        });
    });
    
    describe(@"DidFinishLaunchingWithOptionsAppDelegate", ^{
        it(@"should respond to _r_autotrack_application:didFinishLaunchingWithOptions:", ^{
            UIApplication *application = UIApplication.sharedApplication;
            application.delegate = didFinishLaunchingWithOptionsAppDelegate;
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beFalse];
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];
        });
    });
    
    describe(@"FullAppDelegate", ^{
        it(@"should respond to _r_autotrack_application launching methods", ^{
            UIApplication *application = UIApplication.sharedApplication;
            application.delegate = fullAppDelegate;
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
            [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];
        });
    });
});

SPEC_END
