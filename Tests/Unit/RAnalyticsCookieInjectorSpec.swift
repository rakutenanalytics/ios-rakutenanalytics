import Quick
import Nimble
import WebKit
@testable import RAnalytics

// MARK: - Simple Container Mock

private final class ContainerMock: NSObject, SimpleDependenciesContainable {
    public let notificationHandler: NotificationObservable = NotificationCenter.default
    public let userStorageHandler: UserStorageHandleable = UserDefaultsMock()
    public let adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManagerMock()
    public let httpCookieStore: WKHTTPCookieStorable = WKWebsiteDataStore.default().httpCookieStore
    public let keychainHandler: KeychainHandleable = KeychainHandlerMock()
    public let analyticsTracker = AnalyticsTrackerMock()
    public let locationManager: LocationManageable = LocationManagerMock()
    public let bundle: EnvironmentBundle = Bundle.main
    public let tracker: Trackable = AnalyticsTrackerMock()
}

// MARK: - RAnalyticsCookieInjectorSpec

final class RAnalyticsCookieInjectorSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsCookieInjector") {
            let deviceID = "cc851515e51366f4856d165c3ea117e592db6fbc"
            let idfa = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
            let containerMock = ContainerMock()
            let cookieStore: WKHTTPCookieStore! = containerMock.httpCookieStore as? WKHTTPCookieStore
            let adIdentifierManager: ASIdentifierManagerMock! = containerMock.adIdentifierManager as? ASIdentifierManagerMock
            let cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: containerMock)
            let analyticsCookieName = "ra_uid"

            describe("injectAppToWebTrackingCookie") {
                it("should set expected cookie value using device identifier and idfa") {
                    var cookie: HTTPCookie?
                    adIdentifierManager.advertisingIdentifierUUIDString = idfa
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.value).toEventually(equal("rat_uid%3D\(deviceID)%3Ba_uid%3D\(idfa)"))
                }

                it("should set cookie path to /") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.path).toEventually(equal("/"))
                }

                it("should set cookie name to ra_uid") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.name).toEventually(equal(analyticsCookieName))
                }

                if #available(iOS 13.0, *) {
                    it("should set cookie samesite to none") {
                        var cookie: HTTPCookie?
                        cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                            cookie = $0
                        }
                        expect(cookie?.sameSitePolicy).toAfterTimeout(beNil())
                    }
                }

                it("should set cookie as secure") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                        cookie = $0
                    }
                    expect(cookie?.isSecure).toEventually(beTrue())
                }

                context("when domain param is nil") {
                    it("should set default .rakuten.co.jp domain on cookie") {
                        var cookie: HTTPCookie?
                        cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) {
                            cookie = $0
                        }
                        expect(cookie?.domain).toEventually(equal(".rakuten.co.jp"))
                    }
                }

                context("when domain param is non-nil") {
                    it("should set passed in domain on cookie") {
                        var cookie: HTTPCookie?
                        cookieInjector.injectAppToWebTrackingCookie(domain: ".my-domain.co.jp", deviceIdentifier: deviceID) {
                            cookie = $0
                        }
                        expect(cookie?.domain).toEventually(equal(".my-domain.co.jp"))
                    }
                }

                it("should return nil cookie when device identifier is empty") {
                    var cookie: HTTPCookie?
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: "") {
                        cookie = $0
                    }
                    expect(cookie).toAfterTimeout(beNil())
                }

                it("should inject cookie into WKWebsiteDataStore httpCookieStore") {
                    var hasCookie = false
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) { _ in
                        cookieStore.getAllCookies { cookies in
                            hasCookie = !cookies.filter { $0.name == analyticsCookieName }.isEmpty
                        }
                    }
                    expect(hasCookie).toEventually(beTrue())
                }

                it("should inject cookie into WKWebsiteDataStore httpCookieStore") {
                    var hasCookie = false
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) { _ in
                        cookieStore.getAllCookies { cookies in
                            hasCookie = !cookies.filter { $0.name == analyticsCookieName }.isEmpty
                        }
                    }
                    expect(hasCookie).toEventually(beTrue())
                }

                it("should replace the existing cookie by the new one that has the same name into WKWebsiteDataStore httpCookieStore") {
                    var previousCookie: HTTPCookie?
                    var replacedCookie: HTTPCookie?
                    var ratCookies: [HTTPCookie]?

                    cookieInjector.injectAppToWebTrackingCookie(domain: "https://domain1.com", deviceIdentifier: deviceID) {
                        previousCookie = $0

                        cookieInjector.injectAppToWebTrackingCookie(domain: "https://domain2.com", deviceIdentifier: deviceID) {
                            replacedCookie = $0

                            cookieStore.getAllCookies { cookies in
                                ratCookies = cookies.filter { $0.name == analyticsCookieName }
                            }
                        }
                    }

                    expect(previousCookie?.domain).toEventually(equal("https://domain1.com"))
                    expect(replacedCookie?.domain).to(equal("https://domain2.com"))
                    expect(ratCookies?.count).to(equal(1))
                    expect(ratCookies?.first?.name).to(equal(analyticsCookieName))
                    expect(ratCookies?.first?.domain).to(equal("https://domain2.com"))
                }
            }
        }
    }
}
