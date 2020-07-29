#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import "../../RAnalytics/Util/Private/_RAdvertisingIdentifierRequester.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(RAdvertisingIdentifierRequesterTests)

describe(@"RAdvertisingIdentifierRequester", ^{
    describe(@"advertisingIdentifier", ^{
        context(@"advertising tracking is not enabled", ^{
            it(@"should return nil", ^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(NO)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierRequester performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beFalse];
                
                NSString *advertisingIdentifier = [_RAdvertisingIdentifierRequester performSelector:@selector(advertisingIdentifier)];
                [[advertisingIdentifier should] beNil];
            });
        });
        
        context(@"advertising tracking is enabled", ^{
            beforeAll(^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(YES)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierRequester performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beTrue];
            });
            
            it(@"should return nil when idfa UUID equals 00000000-0000-0000-0000-000000000000", ^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierUUIDString) andReturn:@"00000000-0000-0000-0000-000000000000"];
                
                NSString *advertisingIdentifier = [_RAdvertisingIdentifierRequester performSelector:@selector(advertisingIdentifier)];
                [[advertisingIdentifier should] beNil];
            });
            
            it(@"should return 1234-5678-9123-4563 when idfa UUID equals 1234-5678-9123-4563", ^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierUUIDString) andReturn:@"1234-5678-9123-4563"];
                
                NSString *advertisingIdentifier = [_RAdvertisingIdentifierRequester performSelector:@selector(advertisingIdentifier)];
                [[advertisingIdentifier should] equal:@"1234-5678-9123-4563"];
            });
        });
    });
    
    describe(@"requestAdvertisingIdentifier", ^{
        context(@"advertising tracking is not enabled", ^{
            beforeAll(^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(NO)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierRequester performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beFalse];
            });
            
            it(@"completion should return nil in any case", ^{
                [_RAdvertisingIdentifierRequester requestAdvertisingIdentifier:^(NSString * _Nullable idfa) {
                    [[idfa shouldEventually] beNil];
                }];
            });
        });
        
        context(@"advertising tracking is enabled", ^{
            beforeAll(^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierIsAuthorized) andReturn:theValue(YES)];
                
                BOOL advertisingIdentifierIsAuthorized = [_RAdvertisingIdentifierRequester performSelector:@selector(advertisingIdentifierIsAuthorized)];
                [[theValue(advertisingIdentifierIsAuthorized) should] beTrue];
            });
            
            it(@"completion should return nil when idfa UUIDString is 00000000-0000-0000-0000-000000000000", ^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierUUIDString) andReturn:@"00000000-0000-0000-0000-000000000000"];
                
                [_RAdvertisingIdentifierRequester requestAdvertisingIdentifier:^(NSString * _Nullable idfa) {
                    [[idfa shouldEventually] beNil];
                }];
            });
            
            it(@"completion should return 1234-5678-9123-4563 when idfa UUIDString is 1234-5678-9123-4563", ^{
                [_RAdvertisingIdentifierRequester stub:@selector(advertisingIdentifierUUIDString) andReturn:@"1234-5678-9123-4563"];
                
                [_RAdvertisingIdentifierRequester requestAdvertisingIdentifier:^(NSString * _Nullable idfa) {
                    [[idfa shouldEventually] equal:@"1234-5678-9123-4563"];
                }];
            });
        });
    });
});

SPEC_END
