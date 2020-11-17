#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import <RAnalytics/RAnalytics-Swift.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"

@interface RAnalyticsHandler1 : NSObject
@end
@implementation RAnalyticsHandler1: NSObject
@end

@interface RAnalyticsHandler2 : NSObject
@end
@implementation RAnalyticsHandler2: NSObject
@end

@interface RAnalyticsHandler3 : NSObject
@end
@implementation RAnalyticsHandler3: NSObject
@end

@interface RAnalyticsHandler4 : NSObject
@end
@implementation RAnalyticsHandler4: NSObject
@end

SPEC_BEGIN(AnyDependenciesContainerTests)

describe(@"AnyDependenciesContainer", ^{
    describe(@"resolve", ^{
        it(@"should return nil when there are not dependencies", ^{
            AnyDependenciesContainer *dependenciesContainer = AnyDependenciesContainer.new;
            [[[dependenciesContainer resolveObject:RAnalyticsHandler1.self] should] beNil];
            [[[dependenciesContainer resolveObject:RAnalyticsHandler2.self] should] beNil];
            [[[dependenciesContainer resolveObject:RAnalyticsHandler3.self] should] beNil];
        });
        it(@"should return nil when the type is not found", ^{
            AnyDependenciesContainer *dependenciesContainer = AnyDependenciesContainer.new;
            [dependenciesContainer registerObject:RAnalyticsHandler2.new];
            [dependenciesContainer registerObject:RAnalyticsHandler3.new];
            [[[dependenciesContainer resolveObject:RAnalyticsHandler1.self] should] beNil];
        });
        it(@"should return the correct instance when the type is found", ^{
            AnyDependenciesContainer *dependenciesContainer = AnyDependenciesContainer.new;
            NSObject *a = RAnalyticsHandler1.new;
            NSObject *b = RAnalyticsHandler2.new;
            NSObject *c = RAnalyticsHandler3.new;
            [dependenciesContainer registerObject:a];
            [[theValue([dependenciesContainer registerObject:a]) should] equal:theValue(NO)];
            [dependenciesContainer registerObject:b];
            [[theValue([dependenciesContainer registerObject:b]) should] equal:theValue(NO)];
            [dependenciesContainer registerObject:c];
            [[theValue([dependenciesContainer registerObject:c]) should] equal:theValue(NO)];
            [[[dependenciesContainer resolveObject:RAnalyticsHandler1.self] should] equal:a];
            [[[dependenciesContainer resolveObject:RAnalyticsHandler2.self] should] equal:b];
            [[[dependenciesContainer resolveObject:RAnalyticsHandler3.self] should] equal:c];
            [[[dependenciesContainer resolveObject:RAnalyticsHandler4.self] should] beNil];
        });
    });
});

SPEC_END
