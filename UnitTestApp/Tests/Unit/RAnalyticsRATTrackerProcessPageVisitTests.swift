// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable control_statement

import Foundation
import Testing
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRATTrackerProcessPageVisitTests

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerProcessPageVisitTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("Event processing")
        struct EventProcessingTests {
            @Suite("Page Visit")
            struct PageVisitTests {
                @Suite("The referral tracking is a Visited Page")
                struct VisitedPageTests {
                    @Suite("Internal origin")
                    struct InternalOriginTests {
                        var helper = ProcessTestHelper.TestHelper()
                        var customWebPage: CustomWebPage!
                        
                        mutating func setUpPageVisit() async {
                            helper.setUp()
                            customWebPage = await MainActor.run {
                                CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                            }
                        }
                        
                        mutating func tearDownPageVisit() {
                            helper.tearDown()
                        }
                        
                        @Suite("page_id is set to TestPage")
                        struct PageIdSetTests {
                            var helper = ProcessTestHelper.TestHelper()
                            var customWebPage: CustomWebPage!
                            
                            mutating func setUpPageVisit() async {
                                helper.setUp()
                                customWebPage = await MainActor.run {
                                    CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                }
                            }
                            
                            mutating func tearDownPageVisit() {
                                helper.tearDown()
                            }
                            
                            @Suite("The view controller contains a web view")
                            struct WebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                var customWebPage: CustomWebPage!
                                
                                mutating func setUpPageVisit() async {
                                    helper.setUp()
                                    customWebPage = await MainActor.run {
                                        CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                    }
                                }
                                
                                mutating func tearDownPageVisit() {
                                    helper.tearDown()
                                }
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to the page identifier")
                                mutating func testShouldProcessPageVisitWithPageId() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == "TestPage")
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.inner.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    #expect(cpPayload?["title"] as? String == "CustomWebPageTitle")
                                    #expect(cpPayload?["url"] as? String == "https://rat.rakuten.co.jp/")
                                }
                            }
                            
                            @Suite("The view controller does not contain a web view")
                            struct NoWebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to the page identifier")
                                mutating func testShouldProcessPageVisitWithPageId() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == "TestPage")
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.inner.toString)
                                }
                                
                                @Test("should process the pageVisit event with a non-nil title and a nil url")
                                mutating func testShouldProcessPageVisitWithTitleAndNilUrl() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomPageTitle")
                                    #expect(cpPayload?["url"] as? String == nil)
                                }
                            }
                        }
                        
                        @Suite("page_id is nil")
                        struct PageIdNilTests {
                            var helper = ProcessTestHelper.TestHelper()
                            var customWebPage: CustomWebPage!
                            
                            mutating func setUpPageVisit() async {
                                helper.setUp()
                                customWebPage = await MainActor.run {
                                    CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                }
                            }
                            
                            mutating func tearDownPageVisit() {
                                helper.tearDown()
                            }
                            
                            @Suite("The view controller contains a web view")
                            struct WebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                var customWebPage: CustomWebPage!
                                
                                mutating func setUpPageVisit() async {
                                    helper.setUp()
                                    customWebPage = await MainActor.run {
                                        CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                    }
                                }
                                
                                mutating func tearDownPageVisit() {
                                    helper.tearDown()
                                }
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to CustomPage")
                                mutating func testShouldProcessPageVisitWithCustomPage() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == NSStringFromClass(CustomWebPage.self))
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.inner.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomWebPageTitle")
                                    #expect(cpPayload?["url"] as? String == "https://rat.rakuten.co.jp/")
                                }
                            }
                            
                            @Suite("The view controller does not contain a web view")
                            struct NoWebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to CustomPage")
                                mutating func testShouldProcessPageVisitWithCustomPage() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == NSStringFromClass(CustomPage.self))
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.inner.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .inner
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomPageTitle")
                                    #expect(cpPayload?["url"] as? String == nil)
                                }
                            }
                        }
                    }
                    
                    @Suite("External origin")
                    struct ExternalOriginTests {
                        var helper = ProcessTestHelper.TestHelper()
                        var customWebPage: CustomWebPage!
                        
                        mutating func setUpPageVisit() async {
                            helper.setUp()
                            customWebPage = await MainActor.run {
                                CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                            }
                        }
                        
                        mutating func tearDownPageVisit() {
                            helper.tearDown()
                        }
                        
                        @Suite("page_id is set to TestPage")
                        struct PageIdSetTests {
                            var helper = ProcessTestHelper.TestHelper()
                            var customWebPage: CustomWebPage!
                            
                            mutating func setUpPageVisit() async {
                                helper.setUp()
                                customWebPage = await MainActor.run {
                                    CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                }
                            }
                            
                            mutating func tearDownPageVisit() {
                                helper.tearDown()
                            }
                            
                            @Suite("The view controller contains a web view")
                            struct WebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                var customWebPage: CustomWebPage!
                                
                                mutating func setUpPageVisit() async {
                                    helper.setUp()
                                    customWebPage = await MainActor.run {
                                        CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                    }
                                }
                                
                                mutating func tearDownPageVisit() {
                                    helper.tearDown()
                                }
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to the page identifier")
                                mutating func testShouldProcessPageVisitWithPageId() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == "TestPage")
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    #expect(cpPayload?["title"] as? String == "CustomWebPageTitle")
                                    #expect(cpPayload?["url"] as? String == "https://rat.rakuten.co.jp/")
                                }
                            }
                            
                            @Suite("The view controller does not contain a web view")
                            struct NoWebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to the page identifier")
                                mutating func testShouldProcessPageVisitWithPageId() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == "TestPage")
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString)
                                }
                                
                                @Test("should process the pageVisit event with a non-nil title and a nil url")
                                mutating func testShouldProcessPageVisitWithTitleAndNilUrl() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomPageTitle")
                                    #expect(cpPayload?["url"] as? String == nil)
                                }
                            }
                        }
                        
                        @Suite("page_id is nil")
                        struct PageIdNilTests {
                            var helper = ProcessTestHelper.TestHelper()
                            var customWebPage: CustomWebPage!
                            
                            mutating func setUpPageVisit() async {
                                helper.setUp()
                                customWebPage = await MainActor.run {
                                    CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                }
                            }
                            
                            mutating func tearDownPageVisit() {
                                helper.tearDown()
                            }
                            
                            @Suite("The view controller contains a web view")
                            struct WebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                var customWebPage: CustomWebPage!
                                
                                mutating func setUpPageVisit() async {
                                    helper.setUp()
                                    customWebPage = await MainActor.run {
                                        CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                    }
                                }
                                
                                mutating func tearDownPageVisit() {
                                    helper.tearDown()
                                }
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to CustomPage")
                                mutating func testShouldProcessPageVisitWithCustomPage() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == NSStringFromClass(CustomWebPage.self))
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomWebPageTitle")
                                    #expect(cpPayload?["url"] as? String == "https://rat.rakuten.co.jp/")
                                }
                            }
                            
                            @Suite("The view controller does not contain a web view")
                            struct NoWebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to CustomPage")
                                mutating func testShouldProcessPageVisitWithCustomPage() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == NSStringFromClass(CustomPage.self))
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .external
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomPageTitle")
                                    #expect(cpPayload?["url"] as? String == nil)
                                }
                            }
                        }
                    }
                    
                    @Suite("Push origin")
                    struct PushOriginTests {
                        var helper = ProcessTestHelper.TestHelper()
                        var customWebPage: CustomWebPage!
                        
                        mutating func setUpPageVisit() async {
                            helper.setUp()
                            customWebPage = await MainActor.run {
                                CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                            }
                        }
                        
                        mutating func tearDownPageVisit() {
                            helper.tearDown()
                        }
                        
                        @Suite("page_id is set to TestPage")
                        struct PageIdSetTests {
                            var helper = ProcessTestHelper.TestHelper()
                            var customWebPage: CustomWebPage!
                            
                            mutating func setUpPageVisit() async {
                                helper.setUp()
                                customWebPage = await MainActor.run {
                                    CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                }
                            }
                            
                            mutating func tearDownPageVisit() {
                                helper.tearDown()
                            }
                            
                            @Suite("The view controller contains a web view")
                            struct WebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                var customWebPage: CustomWebPage!
                                
                                mutating func setUpPageVisit() async {
                                    helper.setUp()
                                    customWebPage = await MainActor.run {
                                        CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                    }
                                }
                                
                                mutating func tearDownPageVisit() {
                                    helper.tearDown()
                                }
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to the page identifier")
                                mutating func testShouldProcessPageVisitWithPageId() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == "TestPage")
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.push.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    #expect(cpPayload?["title"] as? String == "CustomWebPageTitle")
                                    #expect(cpPayload?["url"] as? String == "https://rat.rakuten.co.jp/")
                                }
                            }
                            
                            @Suite("The view controller does not contain a web view")
                            struct NoWebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to the page identifier")
                                mutating func testShouldProcessPageVisitWithPageId() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == "TestPage")
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.push.toString)
                                }
                                
                                @Test("should process the pageVisit event with a non-nil title and a nil url")
                                mutating func testShouldProcessPageVisitWithTitleAndNilUrl() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomPageTitle")
                                    #expect(cpPayload?["url"] as? String == nil)
                                }
                            }
                        }
                        
                        @Suite("page_id is nil")
                        struct PageIdNilTests {
                            var helper = ProcessTestHelper.TestHelper()
                            var customWebPage: CustomWebPage!
                            
                            mutating func setUpPageVisit() async {
                                helper.setUp()
                                customWebPage = await MainActor.run {
                                    CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                }
                            }
                            
                            mutating func tearDownPageVisit() {
                                helper.tearDown()
                            }
                            
                            @Suite("The view controller contains a web view")
                            struct WebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                var customWebPage: CustomWebPage!
                                
                                mutating func setUpPageVisit() async {
                                    helper.setUp()
                                    customWebPage = await MainActor.run {
                                        CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                                    }
                                }
                                
                                mutating func tearDownPageVisit() {
                                    helper.tearDown()
                                }
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to CustomPage")
                                mutating func testShouldProcessPageVisitWithCustomPage() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == NSStringFromClass(CustomWebPage.self))
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.push.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    await setUpPageVisit()
                                    defer { tearDownPageVisit() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: customWebPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomWebPageTitle")
                                    #expect(cpPayload?["url"] as? String == "https://rat.rakuten.co.jp/")
                                }
                            }
                            
                            @Suite("The view controller does not contain a web view")
                            struct NoWebViewTests {
                                var helper = ProcessTestHelper.TestHelper()
                                
                                @Test("should process the pageVisit event with an internal ref and pgn equal to CustomPage")
                                mutating func testShouldProcessPageVisitWithCustomPage() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var payload: [String: Any]?
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        payload = $0.first
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    try await TestingHelpers.eventually {
                                        payload != nil && cpPayload != nil
                                    }
                                    #expect(payload?[PayloadParameterKeys.pgn] as? String == NSStringFromClass(CustomPage.self))
                                    #expect(cpPayload?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.push.toString)
                                }
                                
                                @Test("should process the pageVisit event with title and url")
                                mutating func testShouldProcessPageVisitWithTitleAndUrl() async throws {
                                    helper.setUp()
                                    defer { helper.tearDown() }
                                    
                                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                    var cpPayload: [String: Any]?
                                    
                                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                    state.origin = .push
                                    state.referralTracking = .page(currentPage: Tracking.customPage)
                                    
                                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                    }
                                    
                                    try await TestingHelpers.eventually {
                                        cpPayload != nil
                                    }
                                    
                                    #expect(cpPayload?["title"] as? String == "CustomPageTitle")
                                    #expect(cpPayload?["url"] as? String == nil)
                                }
                            }
                        }
                    }
                    
                    @Suite("Referral tracking")
                    struct ReferralTrackingTests {
                        var helper = ProcessTestHelper.TestHelper()
                        
                        @Test("should process the second pageVisit event with ref equal to the first pageVisit event's page identifier")
                        mutating func testShouldProcessSecondPageVisitWithRef() async throws {
                            helper.setUp()
                            defer { helper.tearDown() }
                            
                            let firstPage = "FirstPage"
                            let secondPage = "SecondPage"
                            
                            let firstEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": firstPage])
                            let secondEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": secondPage])
                            
                            var payload: [String: Any]?
                            
                            let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                            state.origin = .inner
                            state.referralTracking = .page(currentPage: Tracking.customPage)
                            
                            helper.ratTracker.process(event: firstEvent, state: state)
                            
                            let databaseConfiguration: DatabaseConfiguration! = helper.dependenciesContainer.databaseConfiguration as? DatabaseConfiguration
                            let databaseConnection = helper.databaseConnection!
                            
                            helper.ratTracker.process(event: secondEvent, state: state)
                            
                            try await TestingHelpers.eventuallyAsync(timeout: 5.0) {
                                let rows = DatabaseTestUtils.fetchTableContents(databaseConfiguration.tableName, connection: databaseConnection)
                                guard let last = rows.last, rows.count >= 2 else { return false }
                                
                                payload = try? JSONSerialization.jsonObject(with: last, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any]
                                return payload != nil
                            }
                            #expect((payload)?[PayloadParameterKeys.pgn] as? String == secondPage)
                            #expect((payload)?[PayloadParameterKeys.ref] as? String == firstPage)
                        }
                    }
                }
                
                @Suite("The referral tracking is an App")
                struct ReferralAppTests {
                    var helper = ProcessTestHelper.TestHelper()
                    
                    @Test("should process a pageVisit event and a deeplink event")
                    mutating func testShouldProcessPageVisitAndDeeplinkEvent() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        var payloads = [[String: Any]]()
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.applink, parameters: nil)
                        let state = RAnalyticsState(sessionIdentifier: "sessionIdentifier", deviceIdentifier: "deviceIdentifier")
                        let model = ReferralAppModel(bundleIdentifier: "jp.co.rakuten.app",
                                                     accountIdentifier: 111,
                                                     applicationIdentifier: 222,
                                                     link: "campaignCode",
                                                     component: "news",
                                                     customParameters: ["key1": "value1"])
                        state.referralTracking = .referralApp(model)
                        
                        // Process the applink event - this generates two events: pageVisitForRAT and deeplink
                        // Both are sent synchronously, but database insertion is asynchronous
                        let processed = helper.ratTracker.process(event: event, state: state)
                        #expect(processed == true)
                        
                        // Wait for both events to be inserted into the database
                        // The applink event generates two events that are inserted asynchronously
                        let databaseTableName = helper.dependenciesContainer.databaseConfiguration?.tableName ?? ""
                        let databaseConnection = helper.databaseConnection!
                        let queue = DispatchQueue(label: "com.test.database.queue")
                        
                        // Wait for both payloads to be in the database
                        // Give extra time since database inserts are asynchronous
                        try await TestingHelpers.eventuallyAsync(timeout: 10.0) {
                            // Yield multiple times to allow database operations to complete
                            await Task.yield()
                            await Task.yield()
                            
                            // Check database directly for both payloads
                            var dbPayloads = [[String: Any]]()
                            queue.sync {
                                let result = DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
                                dbPayloads = result.deserialize()
                            }
                            
                            // We need exactly 2 payloads: pageVisitForRAT and deeplink
                            if dbPayloads.count >= 2 {
                                payloads = dbPayloads
                                return true
                            }
                            
                            return false
                        }
                        
                        // Verify the first event is pageVisitForRAT
                        guard let etype1 = payloads.first?[PayloadParameterKeys.etype] as? String,
                              etype1 == RAnalyticsEvent.Name.pageVisitForRAT else {
                            throw NSError(
                                domain: "RAnalyticsRATTrackerProcessPageVisitTests",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "First event should be pageVisitForRAT, got \(payloads.first?[PayloadParameterKeys.etype] as? String ?? "nil")"])
                        }
                        
                        let payload1 = payloads[0]
                        let cpPayload1 = payload1[PayloadParameterKeys.cp] as? [String: Any]
                        
                        let payload2 = payloads[1]
                        let cpPayload2 = payload2[PayloadParameterKeys.cp] as? [String: Any]
                        
                        #expect(payload1[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.pageVisitForRAT)
                        #expect(payload1[PayloadParameterKeys.acc] as? Int == 777)
                        #expect(payload1[PayloadParameterKeys.aid] as? Int == 888)
                        #expect(payload1[PayloadParameterKeys.ref] as? String == "jp.co.rakuten.app")
                        #expect(cpPayload1 != nil)
                        #expect(cpPayload1?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString)
                        #expect(cpPayload1?[CpParameterKeys.Ref.link] as? String == "campaignCode")
                        #expect(cpPayload1?[CpParameterKeys.Ref.component] as? String == "news")
                        
                        #expect(payload2[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.deeplink)
                        #expect(payload2[PayloadParameterKeys.acc] as? Int == 111)
                        #expect(payload2[PayloadParameterKeys.aid] as? Int == 222)
                        #expect(payload2[PayloadParameterKeys.ref] as? String == "jp.co.rakuten.app")
                        #expect(cpPayload2 != nil)
                        #expect(cpPayload2?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString)
                        #expect(cpPayload2?[CpParameterKeys.Ref.link] as? String == "campaignCode")
                        #expect(cpPayload2?[CpParameterKeys.Ref.component] as? String == "news")
                    }
                }
            }
        }
    }
}

// swiftlint:enable line_length
    // swiftlint:enable type_body_length
    // swiftlint:enable function_body_length
    // swiftlint:enable control_statement
