#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import <RAnalytics/RAnalytics-Swift.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(RAdvertisingIdentifierHandlerTests)

describe(@"RAdvertisingIdentifierHandler", ^{
    describe(@"idfa", ^{
        it(@"should return nil when idfa UUID equals 00000000-0000-0000-0000-000000000000", ^{
            ASIdentifierManager *identifierManager = ASIdentifierManager.new;
            [identifierManager stub:@selector(advertisingIdentifierUUIDString) andReturn:@"00000000-0000-0000-0000-000000000000"];
            
            AnyDependenciesContainer *dependenciesContainer = [[AnyDependenciesContainer alloc] init];
            [dependenciesContainer registerObject:identifierManager];
            
            [[theValue([dependenciesContainer registerObject:identifierManager]) should] equal:theValue(NO)];
            
            [[[((ASIdentifierManager *)[dependenciesContainer resolveObject:ASIdentifierManager.class]) advertisingIdentifierUUIDString] should] equal:@"00000000-0000-0000-0000-000000000000"];
            
            RAdvertisingIdentifierHandler *advertisingIdentifierHandler = [[RAdvertisingIdentifierHandler alloc] initWithDependenciesContainer:dependenciesContainer];
            
            [[advertisingIdentifierHandler.idfa should] beNil];
        });
        
        it(@"should return nil when the dependenciesContainer doesn't register identifierManager", ^{
            ASIdentifierManager *identifierManager = ASIdentifierManager.new;
            [identifierManager stub:@selector(advertisingIdentifierUUIDString) andReturn:@"1234-5678-9123-4563"];
            
            AnyDependenciesContainer *dependenciesContainer = [[AnyDependenciesContainer alloc] init];
            
            RAdvertisingIdentifierHandler *advertisingIdentifierHandler = [[RAdvertisingIdentifierHandler alloc] initWithDependenciesContainer:dependenciesContainer];
            
            [[advertisingIdentifierHandler.idfa should] beNil];
        });
        
        it(@"should return 1234-5678-9123-4563 when idfa UUID equals 1234-5678-9123-4563", ^{
            ASIdentifierManager *identifierManager = ASIdentifierManager.new;
            [identifierManager stub:@selector(advertisingIdentifierUUIDString) andReturn:@"1234-5678-9123-4563"];
            
            AnyDependenciesContainer *dependenciesContainer = [[AnyDependenciesContainer alloc] init];
            [dependenciesContainer registerObject:identifierManager];
            
            [[theValue([dependenciesContainer registerObject:identifierManager]) should] equal:theValue(NO)];
            
            [[[((ASIdentifierManager *)[dependenciesContainer resolveObject:ASIdentifierManager.class]) advertisingIdentifierUUIDString] should] equal:@"1234-5678-9123-4563"];
            
            RAdvertisingIdentifierHandler *advertisingIdentifierHandler = [[RAdvertisingIdentifierHandler alloc] initWithDependenciesContainer:dependenciesContainer];
            
            [[advertisingIdentifierHandler.idfa should] equal:@"1234-5678-9123-4563"];
        });
    });
});

SPEC_END
