import Quick
import Nimble
import CoreLocation
import UIKit
@testable import RAnalytics

// MARK: - RAnalyticsStateSpec

final class RAnalyticsStateSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsManager.State") {
            let sessionIdentifier = "CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
            let deviceIdentifier = "deviceId"
            let advertisingIdentifier = "adId"
            let userIdentifier = "userId"
            let easyIdentifier = "easyId"
            let currentVersion = "2.0"
            let lastVersion = "1.0"
            let bundle = Bundle(for: RAnalyticsStateSpec.self)
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
            let stateForVisitedPage: AnalyticsManager.State = {
                let state = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                   deviceIdentifier: deviceIdentifier,
                                                   bundle: bundle)
                state.advertisingIdentifier = advertisingIdentifier
                state.lastKnownLocation = location
                state.loginMethod = .oneTapLogin
                state.origin = .external
                state.lastVersion = "1.0"
                state.lastVersionLaunches = 10
                state.referralTracking = .page(currentPage: currentPage)
                state.sessionStartDate = sessionStartDate
                state.initialLaunchDate = initialLaunchDate
                state.lastLaunchDate = lastLaunchDate
                state.lastUpdateDate = lastUpdateDate
                state.userIdentifier = userIdentifier
                state.easyIdentifier = easyIdentifier
                state.loggedIn = true
                return state
            }()
            let stateForReferralAppTracking: AnalyticsManager.State = {
                let state = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                   deviceIdentifier: deviceIdentifier,
                                                   bundle: bundle)
                state.advertisingIdentifier = advertisingIdentifier
                state.lastKnownLocation = location
                state.loginMethod = .oneTapLogin
                state.origin = .external
                state.lastVersion = "1.0"
                state.lastVersionLaunches = 10
                state.referralTracking = .referralApp(model)
                state.sessionStartDate = sessionStartDate
                state.initialLaunchDate = initialLaunchDate
                state.lastLaunchDate = lastLaunchDate
                state.lastUpdateDate = lastUpdateDate
                state.userIdentifier = userIdentifier
                state.easyIdentifier = easyIdentifier
                state.loggedIn = true
                return state
            }()

            describe("init") {
                it("should have the correct default values") {
                    let state = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                       deviceIdentifier: deviceIdentifier,
                                                       bundle: bundle)
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
                    expect(state.origin).to(equal(.internal))
                    expect(state.referralTracking).to(equal(ReferralTrackingType.none))
                }
            }
            describe("setting") {
                context("Visited page") {
                    it("should have the expected values") {
                        let state = stateForVisitedPage
                        verify(state)
                        expect(state.referralTracking).to(equal(.page(currentPage: currentPage)))
                    }
                }

                context("Referral app tracking") {
                    it("should have the expected values") {
                        let state = stateForReferralAppTracking
                        verify(state)
                        expect(state.referralTracking).to(equal(.referralApp(model)))
                    }
                }

                func verify(_ state: AnalyticsManager.State) {
                    expect(state.sessionIdentifier).to(equal(sessionIdentifier))
                    expect(state.deviceIdentifier).to(equal(deviceIdentifier))
                    expect(state.currentVersion).to(equal(currentVersion))
                    expect(state.advertisingIdentifier).to(equal(advertisingIdentifier))
                    expect(state.lastKnownLocation?.coordinate.latitude).to(equal(location.coordinate.latitude))
                    expect(state.lastKnownLocation?.coordinate.longitude).to(equal(location.coordinate.longitude))
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
            }
            describe("copy") {
                context("Visited page") {
                    it("should have the expected values") {
                        guard let state = stateForVisitedPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        verify(state)
                        expect(state.referralTracking).to(equal(.page(currentPage: currentPage)))
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

                func verify(_ state: AnalyticsManager.State) {
                    expect(state.sessionIdentifier).to(equal(sessionIdentifier))
                    expect(state.deviceIdentifier).to(equal(deviceIdentifier))
                    expect(state.currentVersion).to(equal(currentVersion))
                    expect(state.advertisingIdentifier).to(equal(advertisingIdentifier))
                    expect(state.lastKnownLocation?.coordinate.latitude).to(equal(location.coordinate.latitude))
                    expect(state.lastKnownLocation?.coordinate.longitude).to(equal(location.coordinate.longitude))
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
            }
            describe("equal") {
                context("Visited page") {
                    it("should be true if it has the same properties of an other state") {
                        let state = stateForVisitedPage
                        guard let copiedState = stateForVisitedPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state).to(equal(copiedState))
                    }
                    it("should be false if it has not the same properties of an other state") {
                        let state = stateForVisitedPage
                        let otherState = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                                deviceIdentifier: "differentDeviceId")
                        expect(state).toNot(equal(otherState))
                    }
                    it("should be false if it doesn't match the State type") {
                        let state = stateForVisitedPage
                        let anObject = UIView()
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
            describe("hash") {
                context("Visited page") {
                    it("should be identical if it is a copy of an other state") {
                        let state = stateForVisitedPage
                        guard let copiedState = stateForVisitedPage.copy() as? AnalyticsManager.State else {
                            assertionFailure("AnalyticsManager.State copy fails")
                            return
                        }
                        expect(state.hash).to(equal(copiedState.hash))
                    }
                    it("should not be identical if the properties are different") {
                        let state = stateForVisitedPage
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
