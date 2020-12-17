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
    [IceBaseManipulator addInstanceMethodWithDestinationSelector:@selector(application:willFinishLaunchingWithOptions:)
                            withImplementationFromSourceSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)
                                                       fromClass:IceBase.class
                                                         toClass:appDelegateClass];
    
    [IceBaseManipulator addInstanceMethodWithDestinationSelector:@selector(application:didFinishLaunchingWithOptions:)
                            withImplementationFromSourceSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)
                                                       fromClass:IceBase.class
                                                         toClass:appDelegateClass];
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

@interface Container : NSObject
@property(nonatomic, strong) EmptyAppDelegate *emptyAppDelegate;
@property(nonatomic, strong) PartialAppDelegateWillLaunch *partialAppDelegateWillLaunch;
@property(nonatomic, strong) PartialAppDelegateDidLaunch *partialAppDelegateDidLaunch;
@property(nonatomic, strong) FullAppDelegate *fullAppDelegate;
@property(nonatomic, strong) SwizzledEmptyAppDelegate *swizzledEmptyAppDelegate;
@property(nonatomic, strong) SwizzledPartialAppDelegateWillLaunch *swizzledPartialAppDelegateWillLaunch;
@property(nonatomic, strong) SwizzledPartialAppDelegateDidLaunch *swizzledPartialAppDelegateDidLaunch;
@property(nonatomic, strong) SwizzledFullAppDelegate *swizzledFullAppDelegate;
@end
@implementation Container
@end

@interface UIApplication (Replacement) <UIApplicationDelegate>
@end
@implementation UIApplication (Replacement)

+ (void)replaceMethodWithSelector:(SEL)newSelector
                      toClass:(Class)recipient
                    replacing:(SEL)originalSelector
{
    Method newMethod      = class_getInstanceMethod(self,      newSelector);
    Method originalMethod = class_getInstanceMethod(recipient, originalSelector);
    method_exchangeImplementations(newMethod, originalMethod);
}

@end

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(ClassManipulatorUIApplicationTests)

describe(@"_RAnalyticsClassManipulator", ^{
    __block EmptyAppDelegate *emptyAppDelegate = EmptyAppDelegate.new;
    __block PartialAppDelegateWillLaunch *partialAppDelegateWillLaunch = PartialAppDelegateWillLaunch.new;
    __block PartialAppDelegateDidLaunch *partialAppDelegateDidLaunch = PartialAppDelegateDidLaunch.new;
    __block FullAppDelegate *fullAppDelegate = FullAppDelegate.new;
    __block SwizzledEmptyAppDelegate *swizzledEmptyAppDelegate = SwizzledEmptyAppDelegate.new;
    __block SwizzledPartialAppDelegateWillLaunch *swizzledPartialAppDelegateWillLaunch = SwizzledPartialAppDelegateWillLaunch.new;
    __block SwizzledPartialAppDelegateDidLaunch *swizzledPartialAppDelegateDidLaunch = SwizzledPartialAppDelegateDidLaunch.new;
    __block SwizzledFullAppDelegate *swizzledFullAppDelegate = SwizzledFullAppDelegate.new;
    __block id<UIApplicationDelegate> originalAppDelegate = UIApplication.sharedApplication.delegate;
    
    beforeEach(^{
        UIApplication.sharedApplication.delegate = nil;
    });
    
    afterEach(^{
        [UIApplication replaceMethodWithSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)
                                         toClass:UIApplication.sharedApplication.delegate.class
                                       replacing:@selector(application:willFinishLaunchingWithOptions:)];
        
        [UIApplication replaceMethodWithSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)
                                         toClass:UIApplication.sharedApplication.delegate.class
                                       replacing:@selector(application:didFinishLaunchingWithOptions:)];
    });
    
    afterAll(^{
        [UIApplication.sharedApplication performSelector:@selector(r_autotrack_setApplicationDelegate:) withObject:originalAppDelegate];
    });
    
    context(@"No 3rd party swizzling", ^{
        describe(@"EmptyAppDelegate", ^{
            it(@"should not respond to r_autotrack_application launching methods", ^{
                UIApplication.sharedApplication.delegate = emptyAppDelegate;

                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beFalse];
                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beFalse];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"PartialAppDelegateWillLaunch", ^{
            it(@"should respond to r_autotrack_application:willFinishLaunchingWithOptions:", ^{
                UIApplication.sharedApplication.delegate = partialAppDelegateWillLaunch;

                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beFalse];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"PartialAppDelegateDidLaunch", ^{
            it(@"should respond to r_autotrack_application:didFinishLaunchingWithOptions:", ^{
                UIApplication.sharedApplication.delegate = partialAppDelegateDidLaunch;

                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beFalse];

                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"FullAppDelegate", ^{
            it(@"should respond to r_autotrack_application launching methods", ^{
                UIApplication.sharedApplication.delegate = fullAppDelegate;

                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });
    });
    
    context(@"With 3rd party swizzling", ^{
        describe(@"SwizzledEmptyAppDelegate", ^{
            it(@"should respond to _ice_app launching methods", ^{
                UIApplication.sharedApplication.delegate = swizzledEmptyAppDelegate;

                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(_ice_app:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate _ice_app:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(_ice_app:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate _ice_app:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"SwizzledPartialAppDelegateWillLaunch", ^{
            it(@"should respond to _ice_app:didFinishLaunchingWithOptions:", ^{
                UIApplication.sharedApplication.delegate = swizzledPartialAppDelegateWillLaunch;

                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beFalse];
                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(_ice_app:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate _ice_app:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"SwizzledPartialAppDelegateDidLaunch", ^{
            it(@"should respond to _ice_app:willFinishLaunchingWithOptions:", ^{
                UIApplication.sharedApplication.delegate = swizzledPartialAppDelegateDidLaunch;

                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beFalse];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(_ice_app:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate _ice_app:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });

        describe(@"SwizzledFullAppDelegate", ^{
            it(@"should not respond to _ice_app launching methods", ^{
                UIApplication.sharedApplication.delegate = swizzledFullAppDelegate;

                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:willFinishLaunchingWithOptions:)]) should] beTrue];
                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(r_autotrack_application:didFinishLaunchingWithOptions:)]) should] beTrue];

                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:willFinishLaunchingWithOptions:)]) should] beFalse];
                [[theValue([(id)UIApplication.sharedApplication.delegate respondsToSelector:@selector(_ice_app:didFinishLaunchingWithOptions:)]) should] beFalse];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:willFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication willFinishLaunchingWithOptions:nil];

                [[(id)UIApplication.sharedApplication.delegate should] receive:@selector(r_autotrack_application:didFinishLaunchingWithOptions:) withCount:1];
                [(id)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
            });
        });
    });
});

SPEC_END
