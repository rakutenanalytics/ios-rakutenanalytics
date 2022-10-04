// swiftlint:disable line_length

import Quick
import Nimble
import CoreTelephony
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - SenderSpy

private final class SenderSpy: NSObject, Sendable {
    var sendSpy: ((NSMutableDictionary) -> Void)?

    // MARK: - Sendable

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

// MARK: - RAnalyticsRATTrackerDuplicateSpec

class RAnalyticsRATTrackerDuplicateSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsRATTracker") {
            var ratTracker: RAnalyticsRATTracker!
            let sender = SenderSpy()
            let bundleMock: BundleMock = {
                let bundleMock = BundleMock()
                bundleMock.endpointAddress = URL(string: "https://endpoint.co.jp") // req for RAT init
                return bundleMock
            }()

            beforeEach {
                ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                ratTracker.set(batchingDelay: 0)
                ratTracker.duplicateAccounts.removeAll()
                ratTracker.shouldDuplicateRATEventHandler = nil
                bundleMock.duplicateAccounts = nil
                sender.sendSpy = nil
            }

            describe("duplicateEvent") {
                context("shouldDuplicateRATEventHandler is nil") {
                    context("build time account config non-existent") {
                        it("should generate payloads for duplicate accounts") {
                            // given
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

                            // expect
                            expect(payloads.count).to(equal(accounts.count))
                            payloads.sort { ($0[PayloadParameterKeys.acc] as! Int) < $1[PayloadParameterKeys.acc] as! Int } // swiftlint:disable:this force_cast
                            for (i, account) in accounts.enumerated() {
                                expect(payloads[i][PayloadParameterKeys.acc] as? Int64).to(equal(account.acc))
                                expect(payloads[i][PayloadParameterKeys.aid] as? Int64).to(equal(account.aid))
                                expect(payloads[i]["foo"] as? String).to(equal("bar"))
                            }
                        }
                    }

                    context("build time account config present") {
                        it("should generate payloads when buildtime config added") {
                            // given
                            bundleMock.duplicateAccounts = [
                                RATAccount(accountId: 199, applicationId: 2, disabledEvents: nil)
                            ]
                            let container = SimpleContainerMock()
                            container.bundle = bundleMock
                            ratTracker = RAnalyticsRATTracker(dependenciesContainer: container)

                            // expect
                            sender.sendSpy = { payload in
                                expect(payload[PayloadParameterKeys.acc] as? Int).to(equal(199))
                                expect(payload[PayloadParameterKeys.aid] as? Int).to(equal(2))
                            }
                            ratTracker.duplicateEvent(
                                named: RAnalyticsEvent.Name.initialLaunch,
                                with: NSMutableDictionary(),
                                sender: sender)
                        }
                    }
                }
                context("shouldDuplicateRATEventHandler is present") {
                    context("build time account config non-existent") {
                        it("should generate payloads for duplicate accounts when event is allowed to be duped at runtime") {
                            // given
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

                            // expect
                            let expectedAcc1 = accounts.first
                            expect(payloads.count).to(equal(1))
                            expect(payloads.first?[PayloadParameterKeys.acc] as? Int64).to(equal(expectedAcc1?.acc))
                            expect(payloads.first?[PayloadParameterKeys.aid] as? Int64).to(equal(expectedAcc1?.aid))
                            expect(payloads.first?["foo"] as? String).to(equal("bar"))
                        }

                        it("should not generate payloads for duplicate accounts when the event is not allowed to be duplicated at runtime") {

                            ratTracker.shouldDuplicateRATEventHandler = { eventName, _ in
                                return eventName != RAnalyticsEvent.Name.initialLaunch
                            }

                            var payloads = [NSMutableDictionary]()
                            sender.sendSpy = { payloads.append($0) }
                            ratTracker.duplicateEvent(
                                named: RAnalyticsEvent.Name.initialLaunch,
                                with: NSMutableDictionary(),
                                sender: sender)
                            expect(payloads.isEmpty).to(beTrue())
                        }
                    }
                }
            }
        }
    }
}
