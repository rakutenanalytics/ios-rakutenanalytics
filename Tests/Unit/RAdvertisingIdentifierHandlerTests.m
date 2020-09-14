#import <Kiwi/Kiwi.h>
#import <AdSupport/AdSupport.h>
#import "../../RAnalytics/Util/Private/_RAdvertisingIdentifierHandler.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(RAdvertisingIdentifierHandlerTests)

describe(@"_RAdvertisingIdentifierHandler", ^{
    describe(@"idfa", ^{
        it(@"should return nil when idfa UUID equals 00000000-0000-0000-0000-000000000000", ^{
            [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierUUIDString) andReturn:@"00000000-0000-0000-0000-000000000000"];
            [[[_RAdvertisingIdentifierHandler idfa] should] beNil];
        });
        
        it(@"should return 1234-5678-9123-4563 when idfa UUID equals 1234-5678-9123-4563", ^{
            [_RAdvertisingIdentifierHandler stub:@selector(advertisingIdentifierUUIDString) andReturn:@"1234-5678-9123-4563"];
            [[[_RAdvertisingIdentifierHandler idfa] should] equal:@"1234-5678-9123-4563"];
        });
    });
});

SPEC_END
