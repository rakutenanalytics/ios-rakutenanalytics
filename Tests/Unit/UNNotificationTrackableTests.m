
#import <Kiwi/Kiwi.h>
#import <RAnalytics/_UNNotification+Trackable.h>
#import <RAnalytics/_NSString+Encryption.h>
SPEC_BEGIN(UNNotificationTrackableTests)
describe(@"UNNotificationTrackableTests", ^{
    let(rid, ^id{
        return @"123456";
    });
    let(ridAsTrackingId, ^id{
        return [NSString stringWithFormat:@"rid:%@", rid];
    });
    let(nidKey, ^id{
        return @"notification_id";
    });
    let(nid, ^id {
        return @"654321";
    });
    let(nidAsTrackingId, ^id{
        return [NSString stringWithFormat:@"nid:%@", nid];
    });
    let(alertString, ^id{
        return @"hello world";
    });
    let(alertMsgAsTrackingId, ^id{
        return [NSString stringWithFormat:@"msg:%@",[alertString rat_encrypt]];
    });
    context(@"return a valid tracking id", ^{
        context(@"using the rid in the payload", ^{
            it(@"has only a valid rid", ^{
                NSDictionary *payload = @{@"rid":rid};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"is a background push", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":alertString}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"is a background push with body and title payload", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"content-available is false", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          @"aps": @{@"content-available":@false,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"has notification_id in payload", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          nidKey:nid};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"has notification_id in payload and is background push", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          nidKey:nid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":alertString}};
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
        });
        context(@"using notification_id in payload", ^{
            it(@"has only a valid notification_id", ^{
                NSDictionary *payload = @{nidKey:nid};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"is a background push", ^{
                NSDictionary *payload = @{nidKey:nid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":alertString}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"is a background push with body and title payload", ^{
                NSDictionary *payload = @{nidKey:nid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"content-available is false", ^{
                NSDictionary *payload = @{nidKey:nid,
                                          @"aps": @{@"content-available":@false,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"has an empty rid in payload", ^{
                NSDictionary *payload = @{@"rid":@"",
                                          nidKey:nid};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"has an invalid rid in payload", ^{
                NSDictionary *payload = @{@"rid":@1111,
                                          nidKey:nid};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
        });
        
        context(@"using encrypted alert message in payload", ^{
            it(@"has only a valid alert as String", ^{
                NSDictionary *payload = @{@"aps": @{@"alert":alertString}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has a body in the alert", ^{
                NSDictionary *payload = @{@"aps": @{@"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has a title in the alert ", ^{
                NSDictionary *payload = @{@"aps": @{@"alert":@{@"title":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has a body and title in the alert should use body", ^{
                NSString *titleString = @"titleString";
                NSDictionary *payload = @{@"aps": @{@"alert":@{@"title":titleString,
                                                               @"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"is a background push with body and title payload", ^{
                NSDictionary *payload = @{@"aps": @{@"content-available":@true,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"content-available is false", ^{
                NSDictionary *payload = @{@"aps": @{@"content-available":@false,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has an empty rid and empty nid in payload", ^{
                NSDictionary *payload = @{@"rid":@"",
                                          nidKey:@"",
                                          @"aps": @{@"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has an invalid rid and invalid nid in payload", ^{
                NSDictionary *payload = @{@"rid":@12312,
                                          nidKey:@2322,
                                          @"aps": @{@"alert":@{@"body":alertString}}};
                
                [[[UNNotification trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
        });
    });
    
    context(@"return null", ^{
        it(@"is a silent push notification with valid rid and nid", ^{
            NSDictionary *payload = @{@"aps":@{@"content-available":@true},
                                      @"rid":@"654321",
                                      nidKey:@"123456",
            };
            [[[UNNotification trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"alert with empty string", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@""}};
            [[[UNNotification trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"has invalid notification_id, rid, and aps in the payload", ^{
            NSDictionary *payload = @{@"aps":@{},
                                      @"rid":@"",
                                      nidKey:@""};
            [[[UNNotification trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"does not have an alert in the aps", ^{
            NSDictionary *payload = @{@"aps":@{}};
            [[[UNNotification trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"'s alert dictionary has an empty body", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@{@"body":@""}}};
            [[[UNNotification trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"'s alert dictionary has an empty title", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@{@"title":@""}}};
            [[[UNNotification trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"'s alert dictionary has an empty body and title", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@{@"title":@"",
                                                          @"body":@""}}};
            [[[UNNotification trackingIdentifierFromPayload: payload] should] beNil];
        });
    });
});

SPEC_END


