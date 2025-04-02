// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import SQLite3
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRATTrackerProcessSpec

class RAnalyticsRATTrackerProcessSpec: QuickSpec {
    override class func spec() {
        describe("RAnalyticsRATTracker") {
            let expecter = RAnalyticsRATExpecter()
            var databaseConnection: SQlite3Pointer!
            let dependenciesContainer = SimpleContainerMock()
            let appInfoMock = "{\"xcode\":\"1410.14B47a\",\"sdk\":\"iphonesimulator16.1.inner\",\"deployment_target\":\"11.0\"}"
            let sdkDependenciesMock = ["rsdks_inappmessaging": "7.2.0",
                                       "rsdks_pushpnp": "10.0.0",
                                       "rsdks_geo": "2.2.0",
                                       "rsdks_pitari": "3.0.0"]
            let coreInfosCollectorMock = CoreInfosCollectorMock(appInfo: appInfoMock, sdkDependencies: sdkDependenciesMock)
            var ratTracker: RAnalyticsRATTracker!

            func verifyCoreInfos(for eventName: String) {
                let event = RAnalyticsEvent(name: eventName, parameters: nil)
                var appInfoPayload: String?
                var sdkDependencies: [String: String]?

                expecter.expectEvent(event, state: Tracking.defaultState, equal: eventName) {
                    let cp = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    appInfoPayload = cp?.appInfo
                    sdkDependencies = cp?.sdkDependencies
                }

                expect(appInfoPayload).toEventuallyNot(beNil())
                expect(appInfoPayload).to(equal(appInfoMock))

                expect(sdkDependencies).to(equal(sdkDependenciesMock))
            }

            beforeEach {
                let databaseTableName = "testTableName_RAnalyticsRATTrackerSpec"
                databaseConnection = DatabaseTestUtils.openRegularConnection()!
                let database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)

                let bundle = BundleMock()
                bundle.accountIdentifier = 777
                bundle.applicationIdentifier = 888
                bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!

                dependenciesContainer.bundle = bundle
                dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                dependenciesContainer.session = SwiftyURLSessionMock()
                dependenciesContainer.deviceCapability = DeviceMock()
                dependenciesContainer.telephonyNetworkInfoHandler = TelephonyNetworkInfoMock()
                dependenciesContainer.analyticsStatusBarOrientationGetter = ApplicationMock(.portrait)
                dependenciesContainer.coreInfosCollector = coreInfosCollectorMock
                dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(bundle: bundle,
                                                                                      deviceCapability: dependenciesContainer.deviceCapability,
                                                                                      screenHandler: dependenciesContainer.screenHandler,
                                                                                      telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
                                                                                      notificationHandler: dependenciesContainer.notificationHandler,
                                                                                      analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
                                                                                      reachability: Reachability())

                ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                ratTracker.set(batchingDelay: 0)

                expecter.dependenciesContainer = dependenciesContainer
                expecter.endpointURL = dependenciesContainer.bundle.endpointAddress
                expecter.databaseTableName = dependenciesContainer.databaseConfiguration?.tableName
                expecter.databaseConnection = databaseConnection
                expecter.ratTracker = ratTracker
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
                dependenciesContainer.databaseConfiguration?.database.closeConnection()
                databaseConnection = nil
            }

            describe("process(event:state:)") {
                context("When the RAT identifiers are not set") {
                    it("should return false") {
                        let bundle = BundleMock()
                        bundle.accountIdentifier = 0
                        bundle.applicationIdentifier = 0
                        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")

                        let dependenciesContainerWithoutRatIdsConf = SimpleContainerMock()
                        dependenciesContainerWithoutRatIdsConf.bundle = bundle

                        let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainerWithoutRatIdsConf)
                        let result = ratTracker.process(event: Tracking.defaultEvent, state: Tracking.defaultState)

                        expect(result).to(beFalse())
                    }
                }

                context("When the RAT identifiers are set") {
                    it("should return true") {
                        let bundle = BundleMock()
                        bundle.accountIdentifier = 477
                        bundle.applicationIdentifier = 1
                        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")

                        let dependenciesContainerWithRatIdsConf = SimpleContainerMock()
                        dependenciesContainerWithRatIdsConf.bundle = bundle

                        let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainerWithRatIdsConf)
                        let result = ratTracker.process(event: Tracking.defaultEvent, state: Tracking.defaultState)

                        expect(result).to(beTrue())
                    }
                }

                it("should not process the event if the event name is unknown") {
                    let event = RAnalyticsEvent(name: "", parameters: nil)
                    let processed = ratTracker.process(event: event, state: Tracking.defaultState)
                    expect(processed).to(beFalse())
                }

                it("should process the event if the event name prefix is rat.") {
                    expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent")
                }

                it("should process the initialLaunch event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.initialLaunch, parameters: nil)
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.initialLaunch)
                }

                it("should process the install event with Core Infos") {
                    verifyCoreInfos(for: RAnalyticsEvent.Name.install)
                }

                it("should process the sessionStart event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                    var cpPayload: [String: Any]?

                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.sessionStart) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    expect(cpPayload).toEventuallyNot(beNil())

                    let daysSinceLastUse: Int! = cpPayload?["days_since_last_use"] as? Int
                    let daysSinceFirstUse: Int! = cpPayload?["days_since_first_use"] as? Int
                    expect(daysSinceLastUse).to(beGreaterThanOrEqualTo(0))
                    expect(daysSinceLastUse).to(equal(daysSinceFirstUse - 2))
                }

                it("should process the sessionEnd event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.sessionEnd)
                }

                context("applicationUpdate event") {
                    it("should process the applicationUpdate event with Core Infos") {
                        verifyCoreInfos(for: RAnalyticsEvent.Name.applicationUpdate)
                    }

                    it("should process the applicationUpdate event with launches_since_last_upgrade and days_since_last_upgrade") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.applicationUpdate, parameters: nil)
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.applicationUpdate) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }

                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["launches_since_last_upgrade"] as? Int).to(beGreaterThan(0))
                        expect(cpPayload?["days_since_last_upgrade"] as? Int).to(beGreaterThan(0))
                    }
                }

                context("Login") {
                    it("should process the login event when the login method is oneTapLogin") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                        var cpPayload: [String: Any]?

                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                        state.loginMethod = .oneTapLogin

                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.login) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["login_method"] as? String).to(equal(RAnalyticsLoginMethod.oneTapLogin.toString))
                    }

                    it("should process the login event when the login method is passwordInput") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                        var cpPayload: [String: Any]?

                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                        state.loginMethod = .passwordInput

                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.login) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["login_method"] as? String).to(equal(RAnalyticsLoginMethod.passwordInput.toString))
                    }

                    it("should process the login event with an empty cp when the login method is other") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                        var cpPayload: [String: Any]?

                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                        state.loginMethod = .other

                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.login) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        
                        QuickSpec.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                            expect(cpPayload).to(beNil())
                        }
                    }
                }

                context("Logout") {
                    it("should process the logout event when the login method is local") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout,
                                                    parameters: [RAnalyticsEvent.Parameter.logoutMethod: RAnalyticsEvent.LogoutMethod.local])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["logout_method"] as? String).to(equal(RAnalyticsEvent.LogoutMethod.local.toLogoutString))
                    }

                    it("should process the logout event when the login method is global") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout,
                                                    parameters: [RAnalyticsEvent.Parameter.logoutMethod: RAnalyticsEvent.LogoutMethod.global])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["logout_method"] as? String).to(equal(RAnalyticsEvent.LogoutMethod.global.toLogoutString))
                    }

                    it("should process the logout event with an empty cp when the login method is empty") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout, parameters: nil)
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventually(beNil())
                    }
                }

                context("Login Failure") {
                    it("should process the loginFailure event when there is a password login error") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                    parameters: ["type": "password_login", "rae_error": "invalid_grant"])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["type"] as? String).to(equal("password_login"))
                        expect(cpPayload?["rae_error"] as? String).to(equal("invalid_grant"))
                    }

                    it("should process the loginFailure event when there is a sso login error") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                    parameters: ["type": "sso_login", "rae_error": "invalid_scope"])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["type"] as? String).to(equal("sso_login"))
                        expect(cpPayload?["rae_error"] as? String).to(equal("invalid_scope"))
                    }

                    it("should process the loginFailure event when there is a IDSDK login error") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                    parameters: ["idsdk_error": "IDSDK Login Error", "idsdk_error_message": "Network Error"])
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(cpPayload).toEventuallyNot(beNil())
                        expect(cpPayload?["idsdk_error"] as? String).to(equal("IDSDK Login Error"))
                        expect(cpPayload?["idsdk_error_message"] as? String).to(equal("Network Error"))
                    }
                }

                context("Page Visit") {
                    var customWebPage: CustomWebPage!

                    beforeEach {
                        customWebPage = CustomWebPage(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                    }
                    
                    context("The referral tracking is a Visited Page") {
                        func verifyPageTracking(origin: RAnalyticsOrigin) {
                            context("page_id is set to TestPage") {
                                context("The view controller contains a web view") {
                                    it("should process the pageVisit event with an internal ref and pgn equal to the page identifier") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                        var payload: [String: Any]?
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: customWebPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            payload = $0.first
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }
                                        expect(payload).toEventuallyNot(beNil())
                                        expect(cpPayload).toNot(beNil())
                                        expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal("TestPage"))
                                        expect(cpPayload?[CpParameterKeys.Ref.type] as? String).to(equal(origin.toString))
                                    }

                                    it("should process the pageVisit event with title and url") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: customWebPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }

                                        expect(cpPayload).toEventuallyNot(beNil())
                                        expect(cpPayload?["title"] as? String).to(equal("CustomWebPageTitle"))
                                        expect(cpPayload?["url"] as? String).to(equal("https://rat.rakuten.co.jp/"))
                                    }
                                }

                                context("The view controller does not contain a web view") {
                                    it("should process the pageVisit event with an internal ref and pgn equal to the page identifier") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                        var payload: [String: Any]?
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: Tracking.customPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            payload = $0.first
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }
                                        expect(payload).toEventuallyNot(beNil())
                                        expect(cpPayload).toNot(beNil())
                                        expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal("TestPage"))
                                        expect(cpPayload?[CpParameterKeys.Ref.type] as? String).to(equal(origin.toString))
                                    }

                                    it("should process the pageVisit event with a non-nil title and a nil url") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: Tracking.customPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }

                                        expect(cpPayload).toEventuallyNot(beNil())

                                        expect(cpPayload?["title"] as? String).to(equal("CustomPageTitle"))
                                        expect(cpPayload?["url"] as? String).to(beNil())
                                    }
                                }
                            }

                            context("page_id is nil") {
                                context("The view controller contains a web view") {
                                    it("should process the pageVisit event with an internal ref and pgn equal to CustomPage") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                        var payload: [String: Any]?
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: customWebPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            payload = $0.first
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }
                                        expect(payload).toEventuallyNot(beNil())
                                        expect(cpPayload).toNot(beNil())
                                        expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal(NSStringFromClass(CustomWebPage.self)))
                                        expect(cpPayload?[CpParameterKeys.Ref.type] as? String).to(equal(origin.toString))
                                    }

                                    it("should process the pageVisit event with title and url") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: customWebPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }

                                        expect(cpPayload).toEventuallyNot(beNil())

                                        expect(cpPayload?["title"] as? String).to(equal("CustomWebPageTitle"))
                                        expect(cpPayload?["url"] as? String).to(equal("https://rat.rakuten.co.jp/"))
                                    }
                                }

                                context("The view controller does not contain a web view") {
                                    it("should process the pageVisit event with an internal ref and pgn equal to CustomPage") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                        var payload: [String: Any]?
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: Tracking.customPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            payload = $0.first
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }
                                        expect(payload).toEventuallyNot(beNil())
                                        expect(cpPayload).toNot(beNil())
                                        expect(payload?[PayloadParameterKeys.pgn] as? String).to(equal(NSStringFromClass(CustomPage.self)))
                                        expect(cpPayload?[CpParameterKeys.Ref.type] as? String).to(equal(origin.toString))
                                    }

                                    it("should process the pageVisit event with title and url") {
                                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                                        var cpPayload: [String: Any]?

                                        let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                        state.origin = origin
                                        state.referralTracking = .page(currentPage: Tracking.customPage)

                                        expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                        }

                                        expect(cpPayload).toEventuallyNot(beNil())

                                        expect(cpPayload?["title"] as? String).to(equal("CustomPageTitle"))
                                        expect(cpPayload?["url"] as? String).to(beNil())
                                    }
                                }
                            }
                        }

                        context("Internal origin") {
                            verifyPageTracking(origin: .inner)
                        }

                        context("External origin") {
                            verifyPageTracking(origin: .external)
                        }

                        context("Push origin") {
                            verifyPageTracking(origin: .push)
                        }

                        context("Referral tracking") {
                            it("should process the second pageVisit event with ref equal to the first pageVisit event's page identifier") {
                                let firstPage = "FirstPage"
                                let secondPage = "SecondPage"

                                let firstEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": firstPage])
                                let secondEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": secondPage])

                                var payload: [String: Any]?

                                let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                                state.origin = .inner
                                state.referralTracking = .page(currentPage: Tracking.customPage)

                                ratTracker.process(event: firstEvent, state: state)

                                let session = dependenciesContainer.session as? SwiftyURLSessionMock

                                session?.completion = {
                                    let databaseConfiguration: DatabaseConfiguration! = dependenciesContainer.databaseConfiguration as? DatabaseConfiguration
                                    let data = DatabaseTestUtils.fetchTableContents(databaseConfiguration.tableName,
                                                                                    connection: databaseConnection)[1]
                                    payload = try? JSONSerialization.jsonObject(with: data,
                                                                                options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any]
                                }

                                ratTracker.process(event: secondEvent, state: state)

                                expect(payload).toEventuallyNot(beNil())
                                expect((payload)?[PayloadParameterKeys.pgn] as? String).to(equal(secondPage))
                                expect((payload)?[PayloadParameterKeys.ref] as? String).to(equal(firstPage))
                            }
                        }
                    }

                    context("The referral tracking is an App") {
                        it("should process a pageVisit event and a deeplink event") {
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

                            expecter.expectEvent(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                                payloads = $0
                            }

                            expect(payloads.isEmpty).toEventually(beFalse())
                            expect(payloads.count).to(equal(2))

                            let payload1 = payloads[0]
                            let cpPayload1 = payload1[PayloadParameterKeys.cp] as? [String: Any]

                            let payload2 = payloads[1]
                            let cpPayload2 = payload2[PayloadParameterKeys.cp] as? [String: Any]

                            expect(payload1[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.pageVisitForRAT))
                            expect(payload1[PayloadParameterKeys.acc] as? Int).to(equal(777))
                            expect(payload1[PayloadParameterKeys.aid] as? Int).to(equal(888))
                            expect(payload1[PayloadParameterKeys.ref] as? String).to(equal("jp.co.rakuten.app"))
                            expect(cpPayload1).toNot(beNil())
                            expect(cpPayload1?[CpParameterKeys.Ref.type] as? String).to(equal(RAnalyticsOrigin.external.toString))
                            expect(cpPayload1?[CpParameterKeys.Ref.link] as? String).to(equal("campaignCode"))
                            expect(cpPayload1?[CpParameterKeys.Ref.component] as? String).to(equal("news"))

                            expect(payload2).toNot(beNil())
                            expect(payload2[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.deeplink))
                            expect(payload2[PayloadParameterKeys.acc] as? Int).to(equal(111))
                            expect(payload2[PayloadParameterKeys.aid] as? Int).to(equal(222))
                            expect(payload2[PayloadParameterKeys.ref] as? String).to(equal("jp.co.rakuten.app"))
                            expect(cpPayload2).toNot(beNil())
                            expect(cpPayload2?[CpParameterKeys.Ref.type] as? String).to(equal(RAnalyticsOrigin.external.toString))
                            expect(cpPayload2?[CpParameterKeys.Ref.link] as? String).to(equal("campaignCode"))
                            expect(cpPayload2?[CpParameterKeys.Ref.component] as? String).to(equal("news"))
                        }
                    }
                }

                context("The push notification is received") {
                    context("_rem_push_received_external") {
                        context("request identifier is nil") {
                            it("should process the _rem_push_received event with a tracking identifier") {
                                let trackingIdentifier = "trackingIdentifier"
                                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceivedExternal,
                                                            parameters: [CpParameterKeys.Push.pushNotifyValue: trackingIdentifier])

                                var payload: [String: Any]?
                                var cpPayload: [String: Any]?

                                expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                    payload = $0.first
                                    cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                }
                                expect(payload).toEventuallyNot(beNil())
                                expect(cpPayload).toNot(beNil())
                                expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String).to(equal(trackingIdentifier))
                                expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier]).to(beNil())
                            }

                            it("should process the _rem_push_received event with rid") {
                                var parameters = [String: Any]()
                                parameters[CpParameterKeys.Push.pushNotifyValue] = "rid:123456"

                                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceivedExternal,
                                                            parameters: parameters)

                                var payload: [String: Any]?
                                var cpPayload: [String: Any]?

                                expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                    payload = $0.first
                                    cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                }
                                expect(payload).toEventuallyNot(beNil())
                                expect(cpPayload).toNot(beNil())
                                expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String).to(equal("rid:123456"))
                                expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier]).to(beNil())
                            }
                        }

                        context("request identifier is not nil") {
                            it("should process the _rem_push_received event with a tracking identifier and a request identifier") {
                                let trackingIdentifier = "trackingIdentifier"
                                let requestIdentifier = "requestIdentifier"
                                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceivedExternal,
                                                            parameters: [RAnalyticsEvent.Parameter.pushTrackingIdentifier: trackingIdentifier,
                                                                         RAnalyticsEvent.Parameter.pushRequestIdentifier: requestIdentifier,
                                                                         CpParameterKeys.Push.pushNotifyValue: trackingIdentifier])
                                var payload: [String: Any]?
                                var cpPayload: [String: Any]?

                                expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                    payload = $0.first
                                    cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                }
                                expect(payload).toEventuallyNot(beNil())
                                expect(cpPayload).toNot(beNil())
                                expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String).to(equal(trackingIdentifier))
                                expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String).to(equal(requestIdentifier))
                            }

                            it("should process the _rem_push_received event with rid and a request identifier") {
                                let requestIdentifier = "requestIdentifier"

                                var parameters = [String: Any]()
                                parameters[CpParameterKeys.Push.pushNotifyValue] = "rid:123456"
                                parameters[AnalyticsManager.Event.Parameter.pushRequestIdentifier] = requestIdentifier

                                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceivedExternal, parameters: parameters)

                                var payload: [String: Any]?
                                var cpPayload: [String: Any]?

                                expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                    payload = $0.first
                                    cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                                }
                                expect(payload).toEventuallyNot(beNil())
                                expect(cpPayload).toNot(beNil())
                                expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String).to(equal("rid:123456"))
                                expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String).to(equal(requestIdentifier))
                            }
                        }
                    }
                }

                context("The push notification is opened") {
                    context("_rem_push_notify_external") {
                        it("should process the _rem_push_notify event with a tracking identifier") {
                            let trackingIdentifier = "trackingIdentifier"
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationExternal,
                                                        parameters: [CpParameterKeys.Push.pushNotifyValue: trackingIdentifier])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?
                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationOpenedForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String).to(equal(trackingIdentifier))
                        }
                        
                        it("should process the _rem_push_notify event with rid") {
                            var parameters = [String: Any]()
                            parameters[CpParameterKeys.Push.pushNotifyValue] = "rid:123456"
                            
                            let event = RAnalyticsEvent(name: AnalyticsManager.Event.Name.pushNotificationExternal,
                                                        parameters: parameters)
                            
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?
                            expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationOpenedForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String).to(equal("rid:123456"))
                        }
                    }
                }

                context("Push conversion event") {
                    it("should not process the _rem_push_cv event when request identifier and conversion action are empty") {
                        let event = RAnalyticsEvent(name: AnalyticsManager.Event.Name.pushNotificationConversion,
                                                    parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "",
                                                                 AnalyticsManager.Event.Parameter.pushConversionAction: ""])

                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.processEvent(event, state: Tracking.defaultState) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }

                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())
                        expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String).to(equal(""))
                        expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String).to(equal(""))
                    }

                    it("should not process the _rem_push_cv event when request identifier is empty") {
                        let event = RAnalyticsEvent(name: AnalyticsManager.Event.Name.pushNotificationConversion,
                                                    parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "",
                                                                 AnalyticsManager.Event.Parameter.pushConversionAction: "pushConversionAction"])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.processEvent(event, state: Tracking.defaultState) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }

                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())
                        expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String).to(equal(""))
                        expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String).to(equal("pushConversionAction"))
                    }

                    it("should not process the _rem_push_cv event when conversion action is empty") {
                        let event = RAnalyticsEvent(name: AnalyticsManager.Event.Name.pushNotificationConversion,
                                                    parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "pushRequestIdentifier",
                                                                 AnalyticsManager.Event.Parameter.pushConversionAction: ""])

                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.processEvent(event, state: Tracking.defaultState) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }

                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())
                        expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String).to(equal("pushRequestIdentifier"))
                        expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String).to(equal(""))
                    }

                    it("should process the _rem_push_cv event when request identifier and conversion action are not empty") {
                        let event = RAnalyticsEvent(name: AnalyticsManager.Event.Name.pushNotificationConversion,
                                                    parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "pushRequestIdentifier",
                                                                 AnalyticsManager.Event.Parameter.pushConversionAction: "pushConversionAction"])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationConversion) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())
                        expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String).to(equal("pushRequestIdentifier"))
                        expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String).to(equal("pushConversionAction"))
                    }
                }

                context("PNP events") {
                    context("Push auto registration external event") {
                        verifySuccess(RAnalyticsEvent.Name.pushAutoRegistrationExternal)
                    }

                    context("Push auto unregistration external event") {
                        verifySuccess(RAnalyticsEvent.Name.pushAutoUnregistrationExternal)
                    }

                    func verifySuccess(_ eventName: String) {
                        it("should process the \(eventName) event when parameters is not nil") {
                            let event = RAnalyticsEvent(name: eventName,
                                                        parameters: [CpParameterKeys.PNP.deviceId: Tracking.deviceToken,
                                                                     CpParameterKeys.PNP.pnpClientId: Tracking.pnpClientIdentifier])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?

                            expecter.processEvent(event, state: Tracking.defaultState) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }

                            expect(payload).toEventuallyNot(beNil())
                            expect(cpPayload).toNot(beNil())
                            expect(cpPayload?[CpParameterKeys.PNP.deviceId] as? String).to(equal(Tracking.deviceToken))
                            expect(cpPayload?[CpParameterKeys.PNP.pnpClientId] as? String).to(equal(Tracking.pnpClientIdentifier))
                        }
                    }
                }

                it("should process the discover event with an app name and a store URL") {
                    let discoverEvent = "_rem_discover_event"
                    let appName = "appName"
                    let storeURL = "storeUrl"
                    let event = RAnalyticsEvent(name: discoverEvent,
                                                parameters: ["prApp": appName, "prStoreUrl": storeURL])
                    var payload: [String: Any]?
                    var cpPayload: [String: Any]?

                    expecter.expectEvent(event, state: Tracking.defaultState, equal: discoverEvent) {
                        payload = $0.first
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    expect(payload).toEventuallyNot(beNil())
                    expect(cpPayload).toNot(beNil())

                    let prApp = cpPayload?["prApp"] as? String
                    expect(prApp).to(equal(appName))

                    let prStoreUrl = cpPayload?["prStoreUrl"] as? String
                    expect(prStoreUrl).to(equal(storeURL))
                }

                it("should process the SSOCredentialFound event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.ssoCredentialFound, parameters: ["source": "device"])
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.ssoCredentialFound)
                }

                context("LoginCredentialFound") {
                    it("should process the loginCredentialFound event with icloud source") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginCredentialFound, parameters: ["source": "icloud"])
                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginCredentialFound)
                    }

                    it("should process the loginCredentialFound event with password-manager source") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginCredentialFound, parameters: ["source": "password-manager"])
                        expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginCredentialFound)
                    }
                }

                it("should process the credentialStrategies event") {
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.credentialStrategies,
                                                parameters: ["strategies": ["password-manager": "true"]])
                    expecter.expectEvent(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.credentialStrategies)
                }

                context("Custom") {
                    it("should process the custom event with eventData parameters") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "eventData": ["foo": "bar"]])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).toNot(beNil())

                        let foo = cpPayload?["foo"] as? String
                        expect(foo).to(equal("bar"))
                    }

                    it("should process the custom event without eventData parameters") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName"])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(cpPayload).to(beNil())
                    }

                    it("should not process the custom event without eventName") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["blah": "name", "eventData": ["foo": "bar"]])
                        expect(ratTracker.process(event: event, state: Tracking.defaultState)).to(beFalse())
                    }

                    it("should process the custom event with customAccNumber") {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "customAccNumber": 10])
                        var payload: [String: Any]?

                        expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?[PayloadParameterKeys.acc] as? NSNumber).to(equal(NSNumber(value: 10)))
                    }

                    for accNumber in [0, -2, 6.33] {
                        it("should process the custom event with deafult account number when customAccNumber is \(accNumber)") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                        parameters: ["eventName": "etypeName", "customAccNumber": accNumber])
                            var payload: [String: Any]?

                            expecter.expectEvent(event, state: Tracking.defaultState, equal: "etypeName") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(payload?[PayloadParameterKeys.acc] as? NSNumber).to(equal(NSNumber(value: 777)))
                        }
                    }
                }

                it("should not process an unknown event") {
                    let event = RAnalyticsEvent(name: "unknown", parameters: nil)
                    expect(ratTracker.process(event: event, state: Tracking.defaultState)).to(beFalse())
                }
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
