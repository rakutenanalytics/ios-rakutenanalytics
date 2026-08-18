// swiftlint:disable line_length

import Testing
import CoreTelephony
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - SenderSpy

final class SenderSpy: NSObject, AnalyticsSendable {
    var sendSpy: ((NSMutableDictionary) -> Void)?
    var endpointURL: URL? = URL(string: "https://rakuten.co.jp")
    
    func setBatchingDelayBlock(_ batchingDelayBlock: @autoclosure @escaping BatchingDelayBlock) { }
    func batchingDelayBlock() -> BatchingDelayBlock? { nil }
    func send(jsonObject: Any) {
        guard let dict = jsonObject as? NSMutableDictionary else {
            assertionFailure("SenderSpy.send received unexpected non-NSMutableDictionary param")
            return
        }
        sendSpy?(dict)
    }
}

// MARK: - RAnalyticsRATTrackerDuplicateTests

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerDuplicateTests {
    
    @Suite("addDuplicateAccount")
    struct AddDuplicateAccountTests {
        var ratTracker: RAnalyticsRATTracker!
        let sender = SenderSpy()
        let bundleMock: BundleMock = {
            let bundleMock = BundleMock()
            bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
            return bundleMock
        }()
        
        mutating func setUp() {
            ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
            ratTracker.set(batchingDelay: 0)
            ratTracker.duplicateAccounts.removeAll()
            ratTracker.shouldDuplicateRATEventHandler = nil
            bundleMock.duplicateAccounts = nil
            sender.sendSpy = nil
        }
        
        @Suite("when account and application IDs are zero or negative")
        struct WhenAccountAndApplicationIDsAreZeroOrNegativeTests {
            var ratTracker: RAnalyticsRATTracker!
            let sender = SenderSpy()
            let bundleMock: BundleMock = {
                let bundleMock = BundleMock()
                bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                return bundleMock
            }()
            
            mutating func setUp() {
                ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                ratTracker.set(batchingDelay: 0)
                ratTracker.duplicateAccounts.removeAll()
                ratTracker.shouldDuplicateRATEventHandler = nil
                bundleMock.duplicateAccounts = nil
                sender.sendSpy = nil
            }
            
            @Test("should not add duplicate accounts")
            mutating func testShouldNotAddDuplicateAccounts() {
                setUp()
                
                let accounts: [(acc: Int64, aid: Int64)] = [
                    (acc: -420, aid: 0),
                    (acc: 0, aid: 60),
                    (acc: -420, aid: 60),
                    (acc: 421, aid: -60),
                    (acc: 421, aid: 0)
                ]
                
                accounts.forEach { account in
                    #expect(ratTracker.addDuplicateAccount(accountId: account.0, applicationId: account.1) == false)
                }
            }
        }
        
        @Suite("when account and application IDs are valid")
        struct WhenAccountAndApplicationIDsAreValidTests {
            var ratTracker: RAnalyticsRATTracker!
            let sender = SenderSpy()
            let bundleMock: BundleMock = {
                let bundleMock = BundleMock()
                bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                return bundleMock
            }()
            
            mutating func setUp() {
                ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                ratTracker.set(batchingDelay: 0)
                ratTracker.duplicateAccounts.removeAll()
                ratTracker.shouldDuplicateRATEventHandler = nil
                bundleMock.duplicateAccounts = nil
                sender.sendSpy = nil
            }
            
            @Test("should add duplicate accounts")
            mutating func testShouldAddDuplicateAccounts() {
                setUp()
                
                let accounts: [(acc: Int64, aid: Int64)] = [
                    (acc: 420, aid: 69),
                    (acc: 421, aid: 60)
                ]
                
                accounts.forEach { account in
                    #expect(ratTracker.addDuplicateAccount(accountId: account.0, applicationId: account.1) == true)
                }
            }
        }
    }
    
    @Suite("duplicateEvent")
    struct DuplicateEventTests {
        var ratTracker: RAnalyticsRATTracker!
        let sender = SenderSpy()
        let bundleMock: BundleMock = {
            let bundleMock = BundleMock()
            bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
            return bundleMock
        }()
        
        mutating func setUp() {
            ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
            ratTracker.set(batchingDelay: 0)
            ratTracker.duplicateAccounts.removeAll()
            ratTracker.shouldDuplicateRATEventHandler = nil
            bundleMock.duplicateAccounts = nil
            sender.sendSpy = nil
        }
        
        @Suite("shouldDuplicateRATEventHandler is nil")
        struct ShouldDuplicateRATEventHandlerIsNilTests {
            var ratTracker: RAnalyticsRATTracker!
            let sender = SenderSpy()
            let bundleMock: BundleMock = {
                let bundleMock = BundleMock()
                bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                return bundleMock
            }()
            
            mutating func setUp() {
                ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                ratTracker.set(batchingDelay: 0)
                ratTracker.duplicateAccounts.removeAll()
                ratTracker.shouldDuplicateRATEventHandler = nil
                bundleMock.duplicateAccounts = nil
                sender.sendSpy = nil
            }
            
            @Suite("build time account config non-existent")
            struct BuildTimeAccountConfigNonExistentTests {
                var ratTracker: RAnalyticsRATTracker!
                let sender = SenderSpy()
                let bundleMock: BundleMock = {
                    let bundleMock = BundleMock()
                    bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                    return bundleMock
                }()
                
                mutating func setUp() {
                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                    ratTracker.set(batchingDelay: 0)
                    ratTracker.duplicateAccounts.removeAll()
                    ratTracker.shouldDuplicateRATEventHandler = nil
                    bundleMock.duplicateAccounts = nil
                    sender.sendSpy = nil
                }
                
                @Test("should generate payloads for duplicate accounts")
                mutating func testShouldGeneratePayloadsForDuplicateAccounts() {
                    setUp()
                    
                    let accounts: [(acc: Int64, aid: Int64)] = [
                        (acc: 420, aid: 69),
                        (acc: 421, aid: 60)
                    ].sorted {$0.0 < $1.0}
                    let baseDict = ["foo": "bar"]
                    
                    accounts.forEach { ratTracker.addDuplicateAccount(accountId: $0.0, applicationId: $0.1) }
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.applicationUpdate, parameters: nil)
                    let basePayload = NSMutableDictionary(dictionary: baseDict, copyItems: false)
                    var payloads = [NSMutableDictionary]()
                    sender.sendSpy = { payloads.append($0) }
                    ratTracker.duplicateEvent(named: event.name, with: basePayload, sender: sender)
                    
                    #expect(payloads.count == accounts.count)
                    payloads.sort { ($0[PayloadParameterKeys.acc] as! Int) < $1[PayloadParameterKeys.acc] as! Int } // swiftlint:disable:this force_cast
                    for (i, account) in accounts.enumerated() {
                        #expect(payloads[i][PayloadParameterKeys.acc] as? Int64 == account.acc)
                        #expect(payloads[i][PayloadParameterKeys.aid] as? Int64 == account.aid)
                        #expect(payloads[i]["foo"] as? String == "bar")
                    }
                }
            }
            
            @Suite("build time account config present")
            struct BuildTimeAccountConfigPresentTests {
                var ratTracker: RAnalyticsRATTracker!
                let sender = SenderSpy()
                let bundleMock: BundleMock = {
                    let bundleMock = BundleMock()
                    bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                    return bundleMock
                }()
                
                mutating func setUp() {
                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                    ratTracker.set(batchingDelay: 0)
                    ratTracker.duplicateAccounts.removeAll()
                    ratTracker.shouldDuplicateRATEventHandler = nil
                    bundleMock.duplicateAccounts = nil
                    sender.sendSpy = nil
                }
                
                @Test("should generate payloads when buildtime config added")
                mutating func testShouldGeneratePayloadsWhenBuildtimeConfigAdded() {
                    setUp()
                    
                    bundleMock.duplicateAccounts = [RATAccount(accountId: 199, applicationId: 2, disabledEvents: nil)]
                    let container = SimpleContainerMock()
                    container.bundle = bundleMock
                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: container)
                    
                    sender.sendSpy = { payload in
                        #expect(payload[PayloadParameterKeys.acc] as? Int == 199)
                        #expect(payload[PayloadParameterKeys.aid] as? Int == 2)
                    }
                    ratTracker.duplicateEvent(
                        named: RAnalyticsEvent.Name.initialLaunch,
                        with: NSMutableDictionary(),
                        sender: sender)
                }
            }
        }
        
        @Suite("shouldDuplicateRATEventHandler is present")
        struct ShouldDuplicateRATEventHandlerIsPresentTests {
            var ratTracker: RAnalyticsRATTracker!
            let sender = SenderSpy()
            let bundleMock: BundleMock = {
                let bundleMock = BundleMock()
                bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                return bundleMock
            }()
            
            mutating func setUp() {
                ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                ratTracker.set(batchingDelay: 0)
                ratTracker.duplicateAccounts.removeAll()
                ratTracker.shouldDuplicateRATEventHandler = nil
                bundleMock.duplicateAccounts = nil
                sender.sendSpy = nil
            }
            
            @Suite("build time account config non-existent")
            struct BuildTimeAccountConfigNonExistentTests {
                var ratTracker: RAnalyticsRATTracker!
                let sender = SenderSpy()
                let bundleMock: BundleMock = {
                    let bundleMock = BundleMock()
                    bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                    return bundleMock
                }()
                
                mutating func setUp() {
                    ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                    ratTracker.set(batchingDelay: 0)
                    ratTracker.duplicateAccounts.removeAll()
                    ratTracker.shouldDuplicateRATEventHandler = nil
                    bundleMock.duplicateAccounts = nil
                    sender.sendSpy = nil
                }
                
                @Test("should generate payloads for duplicate accounts when event is allowed to be duped at runtime")
                mutating func testShouldGeneratePayloadsForDuplicateAccountsWhenEventIsAllowedToBeDupedAtRuntime() {
                    setUp()
                    
                    let accounts: [(acc: Int64, aid: Int64)] = [
                        (acc: 420, aid: 69),
                        (acc: 421, aid: 60)
                    ]
                    ratTracker.shouldDuplicateRATEventHandler = { eventName, acc in
                        return acc == 420 && eventName == RAnalyticsEvent.Name.applicationUpdate
                    }
                    let baseDict = ["foo": "bar"]
                    
                    accounts.forEach { ratTracker.addDuplicateAccount(accountId: $0.0, applicationId: $0.1) }
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.applicationUpdate, parameters: nil)
                    let basePayload = NSMutableDictionary(dictionary: baseDict, copyItems: false)
                    var payloads = [NSMutableDictionary]()
                    sender.sendSpy = { payloads.append($0) }
                    ratTracker.duplicateEvent(named: event.name, with: basePayload, sender: sender)
                    
                    let expectedAcc1 = accounts.first
                    #expect(payloads.count == 1)
                    #expect(payloads.first?[PayloadParameterKeys.acc] as? Int64 == expectedAcc1?.acc)
                    #expect(payloads.first?[PayloadParameterKeys.aid] as? Int64 == expectedAcc1?.aid)
                    #expect(payloads.first?["foo"] as? String == "bar")
                }
                
                @Test("should not generate payloads for duplicate accounts when the event is not allowed to be duplicated at runtime")
                mutating func testShouldNotGeneratePayloadsForDuplicateAccountsWhenEventIsNotAllowedToBeDuplicatedAtRuntime() {
                    setUp()
                    
                    ratTracker.shouldDuplicateRATEventHandler = { eventName, _ in
                        return eventName != RAnalyticsEvent.Name.initialLaunch
                    }
                    
                    var payloads = [NSMutableDictionary]()
                    sender.sendSpy = { payloads.append($0) }
                    ratTracker.duplicateEvent(
                        named: RAnalyticsEvent.Name.initialLaunch,
                        with: NSMutableDictionary(),
                        sender: sender)
                    #expect(payloads.isEmpty == true)
                }
            }
        }
    }
}

// swiftlint:enable line_length
