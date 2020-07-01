@import XCTest;
#import <Kiwi/Kiwi.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AppDelegate.h"

#pragma mark - IceBase (Fake FireBase)

@interface IceBaseManipulator: NSObject
@end
@implementation IceBaseManipulator
+ (void)addInstanceMethodWithDestinationSelector:(SEL)destinationSelector
            withImplementationFromSourceSelector:(SEL)sourceSelector
                                       fromClass:(Class)fromClass
                                         toClass:(Class)toClass {
    Method method = class_getInstanceMethod(fromClass, sourceSelector);
    IMP methodIMP = method_getImplementation(method);
    const char *types = method_getTypeEncoding(method);
    if(class_addMethod(toClass, destinationSelector, methodIMP, types)) {
        Method originalMethod = class_getInstanceMethod(toClass, destinationSelector);
        
        class_replaceMethod(toClass,
        sourceSelector,
        method_getImplementation(originalMethod),
        method_getTypeEncoding(originalMethod));
    }
}
@end

@interface IceBase : NSObject
@end
@implementation IceBase
- (void)configureForAppDelegateClass:(Class)appDelegateClass {
    [IceBaseManipulator addInstanceMethodWithDestinationSelector:@selector(application:willFinishLaunchingWithOptions:) withImplementationFromSourceSelector:@selector(_ice_app:willFinishLaunchingWithOptions:) fromClass:IceBase.class toClass:appDelegateClass];
    
    [IceBaseManipulator addInstanceMethodWithDestinationSelector:@selector(application:didFinishLaunchingWithOptions:) withImplementationFromSourceSelector:@selector(_ice_app:didFinishLaunchingWithOptions:) fromClass:IceBase.class toClass:appDelegateClass];
}
- (BOOL)_ice_app:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}

- (BOOL)_ice_app:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
@end

#pragma mark - Empty AppDelegate

@interface EmptyAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation EmptyAppDelegate
@end

#pragma mark - Partial AppDelegate Will Launch

@interface PartialAppDelegateWillLaunch : UIResponder <UIApplicationDelegate>
@end

@implementation PartialAppDelegateWillLaunch
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
@end

#pragma mark - DidFinishLaunchingWithOptions AppDelegate

@interface PartialAppDelegateDidLaunch : UIResponder <UIApplicationDelegate>
@end
@implementation PartialAppDelegateDidLaunch
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

#pragma mark - Swizzled Empty AppDelegate

@interface SwizzledEmptyAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) IceBase *iceBase;
@end
@implementation SwizzledEmptyAppDelegate
- (instancetype)init
{
    self = [super init];
    if (self) {
        _iceBase = IceBase.new;
        [_iceBase configureForAppDelegateClass:self.class];
    }
    return self;
}
@end

#pragma mark - Swizzled Partial AppDelegate Will Launch

@interface SwizzledPartialAppDelegateWillLaunch : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) IceBase *iceBase;
@end
@implementation SwizzledPartialAppDelegateWillLaunch
- (instancetype)init
{
    self = [super init];
    if (self) {
        _iceBase = IceBase.new;
        [_iceBase configureForAppDelegateClass:self.class];
    }
    return self;
}
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
@end

#pragma mark - Swizzled Partial AppDelegate Did Launch

@interface SwizzledPartialAppDelegateDidLaunch : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) IceBase *iceBase;
@end
@implementation SwizzledPartialAppDelegateDidLaunch
- (instancetype)init
{
    self = [super init];
    if (self) {
        _iceBase = IceBase.new;
        [_iceBase configureForAppDelegateClass:self.class];
    }
    return self;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}
@end

#pragma mark - Swizzle Full AppDelegate

@interface SwizzledFullAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) IceBase *iceBase;
@end
@implementation SwizzledFullAppDelegate
- (instancetype)init
{
    self = [super init];
    if (self) {
        _iceBase = IceBase.new;
        [_iceBase configureForAppDelegateClass:self.class];
    }
    return self;
}
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
    __block PartialAppDelegateWillLaunch *partialAppDelegateWillLaunch;
    __block PartialAppDelegateDidLaunch *partialAppDelegateDidLaunch;
    __block FullAppDelegate *fullAppDelegate;
    __block SwizzledEmptyAppDelegate *swizzledEmptyAppDelegate;
    __block SwizzledPartialAppDelegateWillLaunch *swizzledPartialAppDelegateWillLaunch;
    __block SwizzledPartialAppDelegateDidLaunch *swizzledPartialAppDelegateDidLaunch;
    __block SwizzledFullAppDelegate *swizzledFullAppDelegate;
    
    beforeEach(^{
        emptyAppDelegate = nil;
        partialAppDelegateWillLaunch = nil;
        partialAppDelegateDidLaunch = nil;
        fullAppDelegate = nil;
        swizzledEmptyAppDelegate = nil;
        swizzledPartialAppDelegateWillLaunch = nil;
        swizzledPartialAppDelegateDidLaunch = nil;
        swizzledFullAppDelegate = nil;
        UIApplication.sharedApplication.delegate = nil;
    });
    
    afterEach(^{
        UIApplication.sharedApplication.delegate = nil;
        UIApplication.sharedApplication.delegate = AppDelegate.new;
    });
    
    context(@"No Swizzling", ^{
        describe(@"EmptyAppDelegate", ^{
            it(@"should not respond to _r_autotrack_application launching methods", ^{
                emptyAppDelegate = EmptyAppDelegate.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = emptyAppDelegate;
                
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beFalse];
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beFalse];
                
                [[(id)application.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"PartialAppDelegateWillLaunch", ^{
            it(@"should respond to _r_autotrack_application:willFinishLaunchingWithOptions:", ^{
                partialAppDelegateWillLaunch = PartialAppDelegateWillLaunch.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = nil;
                application.delegate = partialAppDelegateWillLaunch;
                
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beFalse];

                [[(id)application.delegate should] receive:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"PartialAppDelegateDidLaunch", ^{
            it(@"should respond to _r_autotrack_application:didFinishLaunchingWithOptions:", ^{
                partialAppDelegateDidLaunch = PartialAppDelegateDidLaunch.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = nil;
                application.delegate = partialAppDelegateDidLaunch;
                
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beFalse];
                
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[(id)application.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"FullAppDelegate", ^{
            it(@"should respond to _r_autotrack_application launching methods", ^{
                fullAppDelegate = FullAppDelegate.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = fullAppDelegate;
                
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];
                
                [[(id)application.delegate should] receive:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });
    });
    
    context(@"With Swizzling", ^{
        describe(@"SwizzledEmptyAppDelegate", ^{
            it(@"should not respond to _r_autotrack_application launching methods", ^{
                swizzledEmptyAppDelegate = SwizzledEmptyAppDelegate.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = swizzledEmptyAppDelegate;
                
                [[theValue([(id)application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];
                
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beTrue];
                
                [[(id)application.delegate should] receive:@selector(_ice_app:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate _ice_app:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(_ice_app:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate _ice_app:application didFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });
        
        describe(@"SwizzledPartialAppDelegateWillLaunch", ^{
            it(@"should respond to _r_autotrack_application:willFinishLaunchingWithOptions:", ^{
                swizzledPartialAppDelegateWillLaunch = SwizzledPartialAppDelegateWillLaunch.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = nil;
                application.delegate = swizzledPartialAppDelegateWillLaunch;
                
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];
                
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beFalse];
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beTrue];
                
                [[(id)application.delegate should] receive:@selector(_ice_app:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate _ice_app:application didFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"SwizzledPartialAppDelegateDidLaunch", ^{
            it(@"should respond to _r_autotrack_application:didFinishLaunchingWithOptions:", ^{
                swizzledPartialAppDelegateDidLaunch = SwizzledPartialAppDelegateDidLaunch.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = nil;
                application.delegate = swizzledPartialAppDelegateDidLaunch;
                
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];
                
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beFalse];

                [[(id)application.delegate should] receive:@selector(_ice_app:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate _ice_app:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"SwizzledFullAppDelegate", ^{
            it(@"should not respond to _r_autotrack_application launching methods", ^{
                swizzledFullAppDelegate = SwizzledFullAppDelegate.new;
                UIApplication *application = UIApplication.sharedApplication;
                application.delegate = swizzledFullAppDelegate;
                
                [[theValue([(id)application.delegate respondsToSelector:@selector(_r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)application.delegate respondsToSelector:@selector(_r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];
                
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beFalse];
                [[theValue([(id)application.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beFalse];
                
                [[(id)application.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application willFinishLaunchingWithOptions:nil];
                
                [[(id)application.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)application.delegate application:application didFinishLaunchingWithOptions:nil];
            });
        });
    });
});

SPEC_END
