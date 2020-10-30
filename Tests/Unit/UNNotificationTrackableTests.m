
#import <Kiwi/Kiwi.h>
#import <RAnalytics/RAnalyticsPushTrackingUtility.h>
#import <OCMock/OCMock.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"

SPEC_BEGIN(RAnalyticsPushTrackingUtilityTests)
describe(@"RAnalyticsPushTrackingUtility", ^{
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
        return [NSString stringWithFormat:@"msg:%@",[alertString performSelector:@selector(rat_encrypt)]];
    });
    context(@"return a valid tracking id", ^{
        context(@"using the rid in the payload", ^{
            it(@"has only a valid rid", ^{
                NSDictionary *payload = @{@"rid":rid};
                
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"is a background push", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":alertString}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"is a background push with body and title payload", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"content-available is false", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          @"aps": @{@"content-available":@false,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"has notification_id in payload", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          nidKey:nid};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
            it(@"has notification_id in payload and is background push", ^{
                NSDictionary *payload = @{@"rid":rid,
                                          nidKey:nid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":alertString}};
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:ridAsTrackingId];
            });
        });
        context(@"using notification_id in payload", ^{
            it(@"has only a valid notification_id", ^{
                NSDictionary *payload = @{nidKey:nid};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"is a background push", ^{
                NSDictionary *payload = @{nidKey:nid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":alertString}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"is a background push with body and title payload", ^{
                NSDictionary *payload = @{nidKey:nid,
                                          @"aps": @{@"content-available":@true,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"content-available is false", ^{
                NSDictionary *payload = @{nidKey:nid,
                                          @"aps": @{@"content-available":@false,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"has an empty rid in payload", ^{
                NSDictionary *payload = @{@"rid":@"",
                                          nidKey:nid};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
            it(@"has an invalid rid in payload", ^{
                NSDictionary *payload = @{@"rid":@1111,
                                          nidKey:nid};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:nidAsTrackingId];
            });
        });
        
        context(@"using encrypted alert message in payload", ^{
            it(@"has only a valid alert as String", ^{
                NSDictionary *payload = @{@"aps": @{@"alert":alertString}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has a body in the alert", ^{
                NSDictionary *payload = @{@"aps": @{@"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has a title in the alert ", ^{
                NSDictionary *payload = @{@"aps": @{@"alert":@{@"title":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has a body and title in the alert should use body", ^{
                NSString *titleString = @"titleString";
                NSDictionary *payload = @{@"aps": @{@"alert":@{@"title":titleString,
                                                               @"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"is a background push with body and title payload", ^{
                NSDictionary *payload = @{@"aps": @{@"content-available":@true,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"content-available is false", ^{
                NSDictionary *payload = @{@"aps": @{@"content-available":@false,
                                                  @"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has an empty rid and empty nid in payload", ^{
                NSDictionary *payload = @{@"rid":@"",
                                          nidKey:@"",
                                          @"aps": @{@"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
            it(@"has an invalid rid and invalid nid in payload", ^{
                NSDictionary *payload = @{@"rid":@12312,
                                          nidKey:@2322,
                                          @"aps": @{@"alert":@{@"body":alertString}}};
                
                [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload:payload] should] equal:alertMsgAsTrackingId];
            });
        });
    });
    
    context(@"return null", ^{
        it(@"is a silent push notification with valid rid and nid", ^{
            NSDictionary *payload = @{@"aps":@{@"content-available":@true},
                                      @"rid":@"654321",
                                      nidKey:@"123456",
            };
            [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"alert with empty string", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@""}};
            [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"has invalid notification_id, rid, and aps in the payload", ^{
            NSDictionary *payload = @{@"aps":@{},
                                      @"rid":@"",
                                      nidKey:@""};
            [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"does not have an alert in the aps", ^{
            NSDictionary *payload = @{@"aps":@{}};
            [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"'s alert dictionary has an empty body", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@{@"body":@""}}};
            [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"'s alert dictionary has an empty title", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@{@"title":@""}}};
            [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload: payload] should] beNil];
        });
        it(@"'s alert dictionary has an empty body and title", ^{
            NSDictionary *payload = @{@"aps":@{@"alert":@{@"title":@"",
                                                          @"body":@""}}};
            [[[RAnalyticsPushTrackingUtility trackingIdentifierFromPayload: payload] should] beNil];
        });
    });
    
    context(@"testing analyticsEventHasBeenSentWith", ^ {
        
        id (^createMockMainBundleWithAppGroupName)(NSString*) = ^(NSString *appGroupId) {
            
            id mockMainBundle = OCMPartialMock([NSBundle mainBundle]);
            OCMStub([mockMainBundle objectForInfoDictionaryKey:RPushAppGroupIdentifierPlistKey]).andReturn(appGroupId);
            return mockMainBundle;
        };
        
        id (^createMockUserDefaultsWith)(NSDictionary*, BOOL) = ^(NSDictionary* openCountDictionary, BOOL initWithSuiteNameIsNull) {
            id mockUserDefaults = OCMClassMock([NSUserDefaults class]);
            OCMStub([mockUserDefaults new]).andReturn(mockUserDefaults);
            
            OCMStub([mockUserDefaults initWithSuiteName:OCMOCK_ANY]).andReturn(initWithSuiteNameIsNull ? nil : mockUserDefaults);
            
            OCMStub([mockUserDefaults dictionaryForKey:RPushOpenCountSentUserDefaultKey]).andReturn(initWithSuiteNameIsNull ? nil : openCountDictionary);
            return mockUserDefaults;
        };
        
        let(sentTrackingId, ^id{
            return @"a_good_tracking_id";
        });
        let(goodOpenCountDictionary, ^id{
            return @{sentTrackingId: @true};
        });
        
        __block id mockMainBundle;
        __block id mockUserDefaults;
        
        afterEach(^{
            [mockMainBundle stopMocking];
            [mockUserDefaults stopMocking];
            mockMainBundle = nil;
            mockUserDefaults = nil;
        });
        
        context(@"should return true", ^{
            it(@"when RRPushAppGroupIdentifierPlistKey is set in the main bundle and the associated UserDefaults has a key value pair (RPushOpenCountSentUserDefaultKey, Dictionary) with a (key,value): a_good_tracking_id: true.", ^{
                
                mockMainBundle = createMockMainBundleWithAppGroupName(@"appGroupId");
                
                mockUserDefaults = createMockUserDefaultsWith(goodOpenCountDictionary, false);
                
                [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beTrue];
            });
        });
        
        context(@"should return false", ^{
            
            context(@"when RRPushAppGroupIdentifierPlistKey is not set in the main bundle", ^{
                
                beforeEach(^{
                    mockMainBundle = createMockMainBundleWithAppGroupName(nil);
                });
                
                context(@"valid open count dictionary", ^{
                    it(@"user defaults init returns nil", ^{
                        
                        mockUserDefaults = createMockUserDefaultsWith(goodOpenCountDictionary, true);
                        
                        [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                    });
                    
                    it(@"user defaults init returns object", ^{
                        
                        mockUserDefaults = createMockUserDefaultsWith(goodOpenCountDictionary, false);
                        
                        [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                    });
                    
                    it(@"tracking is nil", ^{
                        
                        mockUserDefaults = createMockUserDefaultsWith(goodOpenCountDictionary, false);
                        
                        [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                    });
                });
                
                context(@"invalid open count dictionary", ^{
                    context(@"user defaults valid", ^{
                        it(@"user defaults init returns object but openCountDictionary is empty", ^{
                            
                            mockUserDefaults = createMockUserDefaultsWith(@{}, false);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                        
                        it(@"user defaults init returns object but openCountDictionary is nil", ^{
                         
                            mockUserDefaults = createMockUserDefaultsWith(nil, false);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                        
                        it(@"tracking is nil", ^{
                            
                            mockUserDefaults = createMockUserDefaultsWith(nil, false);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                    });
                    
                    context(@"user defaults invalid", ^{
                        it(@"user defaults init returns object but openCountDictionary is empty", ^{
                            
                            mockUserDefaults = createMockUserDefaultsWith(@{}, true);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                        
                        it(@"user defaults init returns object but openCountDictionary is nil", ^{
                         
                            mockUserDefaults = createMockUserDefaultsWith(nil, true);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                        
                        it(@"user defaults init returns object but openCountDictionary is nil with tracking id is nil", ^{
                            
                            mockUserDefaults = createMockUserDefaultsWith(nil, true);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                    });
                });
            });
            
            context(@"when RRPushAppGroupIdentifierPlistKey is set in the main bundle", ^{
                
                beforeEach(^{
                    mockMainBundle = createMockMainBundleWithAppGroupName(@"app group 1");
                });
                
                context(@"valid open count dictionary", ^{
                    it(@"user defaults init returns nil", ^{
                        
                        mockUserDefaults = createMockUserDefaultsWith(goodOpenCountDictionary, true);
                        
                        [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                    });
                    
                    it(@"user defaults init returns nil with nil tracking id", ^{
                        
                        mockUserDefaults = createMockUserDefaultsWith(goodOpenCountDictionary, true);
                        
                        [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                    });
                });
                
                context(@"invalid open count dictionary", ^{
                    context(@"user defaults valid", ^{
                        it(@"user defaults init returns object but openCountDictionary is empty", ^{
                            
                            mockUserDefaults = createMockUserDefaultsWith(@{}, false);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                        
                        it(@"user defaults init returns object but openCountDictionary is nil", ^{
                         
                            mockUserDefaults = createMockUserDefaultsWith(nil, false);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                    });
                    
                    context(@"user defaults invalid", ^{
                        it(@"user defaults init returns object but openCountDictionary is empty", ^{
                            
                            mockUserDefaults = createMockUserDefaultsWith(@{}, true);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                        
                        it(@"user defaults init returns object but openCountDictionary is nil", ^{
                         
                            mockUserDefaults = createMockUserDefaultsWith(nil, true);
                            
                            [[theValue([RAnalyticsPushTrackingUtility analyticsEventHasBeenSentWith:sentTrackingId]) should] beFalse];
                        });
                    });
                });
            });
        });
    });
    
});

SPEC_END


