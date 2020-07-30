#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import "../../RAnalytics/Util/Private/_RAdvertisingIdentifierHandler.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(RAdvertisingIdentifierRequesterTests)

describe(@"RAdvertisingIdentifierRequester", ^{
    describe(@"advertisingIdentifier", ^{
        context(@"advertising tracking is not enabled", ^{
            it(@"should return nil", ^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(NO)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierHandler performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beFalse];
                
                NSString *advertisingIdentifier = [_RAdvertisingIdentifierHandler performSelector:@selector(advertisingIdentifier)];
                [[advertisingIdentifier should] beNil];
            });
        });
        
        context(@"advertising tracking is enabled", ^{
            beforeAll(^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(YES)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierHandler performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beTrue];
            });
            
            it(@"should return nil when idfa UUID equals 00000000-0000-0000-0000-000000000000", ^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierUUIDString) andReturn:@"00000000-0000-0000-0000-000000000000"];
                
                NSString *advertisingIdentifier = [_RAdvertisingIdentifierHandler performSelector:@selector(advertisingIdentifier)];
                [[advertisingIdentifier should] beNil];
            });
            
            it(@"should return 1234-5678-9123-4563 when idfa UUID equals 1234-5678-9123-4563", ^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierUUIDString) andReturn:@"1234-5678-9123-4563"];
                
                NSString *advertisingIdentifier = [_RAdvertisingIdentifierHandler performSelector:@selector(advertisingIdentifier)];
                [[advertisingIdentifier should] equal:@"1234-5678-9123-4563"];
            });
        });
    });
    
    describe(@"idfa", ^{
        context(@"advertising tracking is not enabled", ^{
            beforeAll(^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(NO)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierHandler performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beFalse];
            });
            
            it(@"completion should return nil in any case", ^{
                [[[_RAdvertisingIdentifierHandler idfa] should] beNil];
            });
        });
        
        context(@"advertising tracking is enabled", ^{
            beforeAll(^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(YES)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierHandler performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beTrue];
            });
            
            it(@"completion should return nil when idfa UUIDString is 00000000-0000-0000-0000-000000000000", ^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierUUIDString) andReturn:@"00000000-0000-0000-0000-000000000000"];
                [[[_RAdvertisingIdentifierHandler idfa] should] beNil];
            });
            
            it(@"completion should return 1234-5678-9123-4563 when idfa UUIDString is 1234-5678-9123-4563", ^{
                [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierUUIDString) andReturn:@"1234-5678-9123-4563"];
                [[[_RAdvertisingIdentifierHandler idfa] should] equal:@"1234-5678-9123-4563"];
            });
        });
    });
});

SPEC_END
