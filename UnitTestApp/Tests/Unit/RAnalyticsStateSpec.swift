import Quick
import Nimble
import CoreLocation
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsStateSpec

final class RAnalyticsStateSpec: QuickSpec {
    override class func spec() {
        describe("AnalyticsManager.State") {
            let sessionIdentifier = "CA7A88AR-82FE-40C9-A836-B1B3455DECAF"
            let deviceIdentifier = "deviceId"
            let advertisingIdentifier = "adId"
            let userIdentifier = "userId"
            let easyIdentifier = "easyId"
            let currentVersion = "2.0"
            let lastVersion = "1.0"
            let bundle = BundleMock()
            bundle.shortVersion = currentVersion
            let dateComponents = DateComponents(year: 2016,
                                                month: 6,
                                                day: 10,
                                                hour: 9,
                                                minute: 15,
                                                second: 30)
            let calendar = Calendar(identifier: .gregorian)
            let sessionStartDate = calendar.date(from: dateComponents)
            let initialLaunchDate = calendar.date(from: DateComponents(year: 2016,
                                                                       month: 6,
                                                                       day: 10))
            let lastLaunchDate = calendar.date(from: DateComponents(year: 2016,
                                                                    month: 7,
                                                                    day: 12))
            let lastUpdateDate = calendar.date(from: DateComponents(year: 2016,
                                                                    month: 7,
                                                                    day: 11))
            let currentPage: UIViewController = {
                let viewController = UIViewController()
                viewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
                return viewController
            }()
            let model = ReferralAppModel(bundleIdentifier: "jp.co.rakuten.app",
                                         accountIdentifier: 1,
                                         applicationIdentifier: 2,
                                         link: nil,
                                         component: nil,
                                         customParameters: nil)
            let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)

            let defaultState: AnalyticsManager.State = {
                let state = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                   deviceIdentifier: deviceIdentifier,
                                                   for: bundle)
                state.advertisingIdentifier = advertisingIdentifier
                state.lastKnownLocation = LocationModel(location: location,
                                                        isAction: false,
                                                        actionParameters: nil)
                state.loginMethod = .oneTapLogin
                state.origin = .external
                state.lastVersion = "1.0"
                state.lastVersionLaunches = 10
                state.sessionStartDate = sessionStartDate
                state.initialLaunchDate = initialLaunchDate
                state.lastLaunchDate = lastLaunchDate
                state.lastUpdateDate = lastUpdateDate
                state.userIdentifier = userIdentifier
                state.easyIdentifier = easyIdentifier
                state.loggedIn = true
                return state
            }()

            let stateForVisitedUIKitPage: AnalyticsManager.State = {
                let state: AnalyticsManager.State! = defaultState.copy() as? AnalyticsManager.State
                state.referralTracking = .page(currentPage: currentPage)
                return state
            }()

            let stateForVisitedSwiftUIPage: AnalyticsManager.State = {
                let state: AnalyticsManager.State! = defaultState.copy() as? AnalyticsManager.State
                state.referralTracking = .swiftuiPage(pageName: "MyView")
                return state
            }()

            let stateForReferralAppTracking: AnalyticsManager.State = {
                let state: AnalyticsManager.State! = defaultState.copy() as? AnalyticsManager.State
                state.referralTracking = .referralApp(model)
                return state
            }()

            func verify(_ state: AnalyticsManager.State) {
                expect(state.sessionIdentifier).to(equal(sessionIdentifier))
                expect(state.deviceIdentifier).to(equal(deviceIdentifier))
                expect(state.currentVersion).to(equal(currentVersion))
                expect(state.advertisingIdentifier).to(equal(advertisingIdentifier))
                expect(state.lastKnownLocation?.latitude).to(equal(location.coordinate.latitude))
                expect(state.lastKnownLocation?.longitude).to(equal(location.coordinate.longitude))
                expect(state.sessionStartDate).to(equal(sessionStartDate))
                expect(state.isLoggedIn).to(beTrue())
                expect(state.userIdentifier).to(equal(userIdentifier))
                expect(state.easyIdentifier).to(equal(easyIdentifier))
                expect(state.lastVersion).to(equal(lastVersion))
                expect(state.initialLaunchDate).to(equal(initialLaunchDate))
                expect(state.lastLaunchDate).to(equal(lastLaunchDate))
                expect(state.lastUpdateDate).to(equal(lastUpdateDate))
                expect(state.lastVersionLaunches).to(equal(10))
                expect(state.loginMethod).to(equal(.oneTapLogin))
                expect(state.origin).to(equal(.external))
            }

            describe("init") {
                it("should have the correct default values") {
                    let state = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                       deviceIdentifier: deviceIdentifier,
                                                       for: bundle)
                    expect(state.sessionIdentifier).to(equal(sessionIdentifier))
                    expect(state.deviceIdentifier).to(equal(deviceIdentifier))
                    expect(state.currentVersion).to(equal(currentVersion))
                    expect(state.advertisingIdentifier).to(beNil())
                    expect(state.lastKnownLocation).to(beNil())
                    expect(state.sessionStartDate).to(beNil())
                    expect(state.loggedIn).to(beFalse())
                    expect(state.userIdentifier).to(beNil())
                    expect(state.easyIdentifier).to(beNil())
                    expect(state.lastVersion).to(beNil())
                    expect(state.initialLaunchDate).to(beNil())
                    expect(state.lastLaunchDate).to(beNil())
                    expect(state.lastUpdateDate).to(beNil())
                    expect(state.lastVersionLaunches).to(equal(0))
                    expect(state.loginMethod).to(equal(.other))
                    expect(state.origin).to(equal(.inner))
                    expect(state.referralTracking).to(equal(ReferralTrackingType.none))
                }
            }
            describe("setting") {
                context("Visited UIKit page") {
                    it("should have the expected values") {
                        let state = stateForVisitedUIKitPage
                        verify(state)
                        expect(state.referralTracking).to(equal(.page(currentPage: currentPage)))
                    }
                }

                context("Visited SwiftUI page") {
                    it("should have the expected values") {
                        let state = stateForVisitedSwiftUIPage
                        verify(state)
                        expect(state.referralTracking).to(equal(.swiftuiPage(pageName: "MyView")))
                    }
                }

                context("Referral app tracking") {
                    it("should have the expected values") {
                        let state = stateForReferralAppTracking
                        verify(state)
                        expect(state.referralTracking).to(equal(.referralApp(model)))
                    }
                }
            }
            describe("copy") {
                context("Visited UIKit page") {
                    it("should have the expected values") {
                        guard let state = stateForVisitedUIKitPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        verify(state)
                        expect(state.referralTracking).to(equal(.page(currentPage: currentPage)))
                    }
                }

                context("Visited SwiftUI page") {
                    it("should have the expected values") {
                        guard let state = stateForVisitedSwiftUIPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        verify(state)
                        expect(state.referralTracking).to(equal(.swiftuiPage(pageName: "MyView")))
                    }
                }

                context("Referral app tracking") {
                    it("should have the expected values") {
                        guard let state = stateForReferralAppTracking.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        verify(state)
                        expect(state.referralTracking).to(equal(.referralApp(model)))
                    }
                }
            }
            describe("equal") {
                context("Visited UIKit page") {
                    it("should be true if it has the same properties of an other state") {
                        let state = stateForVisitedUIKitPage
                        guard let copiedState = stateForVisitedUIKitPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state).to(equal(copiedState))
                    }
                    it("should be false if it has not the same properties of an other state") {
                        let state = stateForVisitedUIKitPage
                        let otherState = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                                deviceIdentifier: "differentDeviceId")
                        expect(state).toNot(equal(otherState))
                    }
                    it("should be false if it doesn't match the State type") {
                        let state = stateForVisitedUIKitPage
                        let anObject = NSObject()
                        expect(state).toNot(equal(anObject))
                    }
                }

                context("Visited SwiftUI page") {
                    it("should be true if it has the same properties of an other state") {
                        let state = stateForVisitedSwiftUIPage
                        guard let copiedState = stateForVisitedSwiftUIPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state).to(equal(copiedState))
                    }
                    it("should be false if it has not the same properties of an other state") {
                        let state = stateForVisitedSwiftUIPage
                        let otherState = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                                deviceIdentifier: "differentDeviceId")
                        expect(state).toNot(equal(otherState))
                    }
                    it("should be false if it doesn't match the State type") {
                        let state = stateForVisitedSwiftUIPage
                        let anObject = NSObject()
                        expect(state).toNot(equal(anObject))
                    }
                }

                context("Referral app tracking") {
                    it("should be true if it has the same properties of an other state") {
                        let state = stateForReferralAppTracking
                        guard let copiedState = stateForReferralAppTracking.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state).to(equal(copiedState))
                    }
                    it("should be false if it has not the same properties of an other state") {
                        let state = stateForReferralAppTracking
                        let otherState = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                                deviceIdentifier: "differentDeviceId")
                        expect(state).toNot(equal(otherState))
                    }
                    it("should be false if it doesn't match the State type") {
                        let state = stateForReferralAppTracking
                        let anObject = UIView()
                        expect(state).toNot(equal(anObject))
                    }
                }
            }
            
            describe("uniqueSearchId") {
                context("Generate unique search identifier") {
                    it("should be generated correctly") {
                        let state = defaultState
                        let ckp = state.deviceIdentifier
                        let timestamp = Int(Date().toRatTimestamp)
                        let generatedUniqueId = state.uniqueSearchId
                        expect(generatedUniqueId).to(equal("\(ckp)_\(timestamp)"))
                    }
                }
            }
            
            describe("hash") {
                context("Visited UIKit page") {
                    it("should be identical if it is a copy of an other state") {
                        let state = stateForVisitedUIKitPage
                        guard let copiedState = stateForVisitedUIKitPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state.hash).to(equal(copiedState.hash))
                    }
                    it("should not be identical if the properties are different") {
                        let state = stateForVisitedUIKitPage
                        let otherState = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                                deviceIdentifier: "differentDeviceId")
                        expect(state.hash).toNot(equal(otherState.hash))
                    }
                }

                context("Visited SwiftUI page") {
                    it("should be identical if it is a copy of an other state") {
                        let state = stateForVisitedSwiftUIPage
                        guard let copiedState = stateForVisitedSwiftUIPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state.hash).to(equal(copiedState.hash))
                    }
                    it("should not be identical if the properties are different") {
                        let state = stateForVisitedSwiftUIPage
                        let otherState = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                                deviceIdentifier: "differentDeviceId")
                        expect(state.hash).toNot(equal(otherState.hash))
                    }
                }

                context("Referral app tracking") {
                    it("should be identical if it is a copy of an other state") {
                        let state = stateForReferralAppTracking
                        guard let copiedState = stateForReferralAppTracking.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state.hash).to(equal(copiedState.hash))
                    }
                    it("should not be identical if the properties are different") {
                        let state = stateForReferralAppTracking
                        let otherState = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                                deviceIdentifier: "differentDeviceId")
                        expect(state.hash).toNot(equal(otherState.hash))
                    }
                }
            }
        }
    }
}
