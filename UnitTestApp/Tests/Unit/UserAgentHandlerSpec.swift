import Quick
import Nimble
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - Mock Providers

struct MockDeviceInfoProvider: DeviceInfoProvidable {
    let systemName: String
    let systemVersion: String
    let modelIdentifier: String
    let userInterfaceIdiom: UIUserInterfaceIdiom
}

struct MockLocaleProvider: LocaleProvidable {
    let preferredLanguages: [String]
}

// MARK: - UserAgentHandlerSpec

final class UserAgentHandlerSpec: QuickSpec {
    override class func spec() {
        describe("UserAgentHandler") {
            describe("value(for:)") {
                context("When bundle identifier and short version are provided") {
                    it("should return the expected user agent format") {
                        let bundle = BundleMock.create()
                        bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                        bundle.shortVersion = "1.2.3"
                        
                        let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                        
                        let userAgentHandler = UserAgentHandler(bundle: bundle)
                        let result = userAgentHandler.value(for: state)
                        
                        expect(result).to(equal("jp.co.rakuten.TestApp/1.2.3"))
                    }
                }
                
                context("When bundle identifier and version are provided") {
                    it("should return the expected user agent format") {
                        let bundle = BundleMock.create()
                        bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                        bundle.version = "4.5.6"
                        
                        let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                        
                        let userAgentHandler = UserAgentHandler(bundle: bundle)
                        let result = userAgentHandler.value(for: state)
                        
                        expect(result).to(equal("jp.co.rakuten.TestApp/4.5.6"))
                    }
                }
                
                context("When bundle identifier is nil") {
                    it("should return nil") {
                        let bundle = BundleMock.create()
                        bundle.bundleIdentifier = nil
                        bundle.shortVersion = "1.2.3"
                        
                        let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                        
                        let mockBundle = BundleMock.create()
                        mockBundle.bundleIdentifier = nil
                        
                        let userAgentHandler = UserAgentHandler(bundle: mockBundle)
                        let result = userAgentHandler.value(for: state)
                        
                        expect(result).to(beNil())
                    }
                }
                
                context("When current version is nil") {
                    it("should return only bundle identifier") {
                        let bundle = BundleMock.create()
                        bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                        bundle.shortVersion = nil
                        bundle.version = nil
                        
                        let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                        
                        let userAgentHandler = UserAgentHandler(bundle: bundle)
                        let result = userAgentHandler.value(for: state)
                        
                        expect(result).to(equal("jp.co.rakuten.TestApp/"))
                    }
                }
            }
            
            describe("enrichedValue(for:)") {
                context("When all parameters are provided") {
                    it("should return the enriched user agent with correct format") {
                        let bundle = BundleMock.create()
                        bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                        bundle.shortVersion = "1.2.3"
                        bundle.preferredLocalization = "japanese"
                        
                        let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                        
                        let mockDevice = MockDeviceInfoProvider(
                            systemName: "iOS",
                            systemVersion: "15.0",
                            modelIdentifier: "iPhone14,2",
                            userInterfaceIdiom: .phone
                        )
                        
                        let userAgentHandler = UserAgentHandler(bundle: bundle,
                                                                deviceInfoProvider: mockDevice,
                                                                localeProvider: DefaultLocaleProvider())
                        let result = userAgentHandler.enrichedValue(for: state)
                        
                        expect(result).to(equal("jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; ja; Analytics/\(CoreHelpers.Constants.sdkVersion))"))
                    }
                }
                
                context("When bundle identifier is nil") {
                    it("should return nil") {
                        let bundle = BundleMock.create()
                        bundle.bundleIdentifier = nil
                        bundle.shortVersion = "1.2.3"
                        
                        let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                        
                        let mockDevice = MockDeviceInfoProvider(
                            systemName: "iOS",
                            systemVersion: "15.0",
                            modelIdentifier: "iPhone14,2",
                            userInterfaceIdiom: .phone
                        )
                        
                        let userAgentHandler = UserAgentHandler(bundle: bundle,
                                                                deviceInfoProvider: mockDevice,
                                                                localeProvider: DefaultLocaleProvider())
                        let result = userAgentHandler.enrichedValue(for: state)
                        
                        expect(result).to(beNil())
                    }
                }
                
                context("When current version is nil") {
                    it("should return bundle identifier only") {
                        let bundle = BundleMock.create()
                        bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                        bundle.shortVersion = nil
                        bundle.version = nil
                        bundle.preferredLocalization = "japanese"
                        
                        let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                        
                        let mockDevice = MockDeviceInfoProvider(
                            systemName: "iOS",
                            systemVersion: "15.0",
                            modelIdentifier: "iPhone14,2",
                            userInterfaceIdiom: .phone
                        )
                        
                        let userAgentHandler = UserAgentHandler(bundle: bundle,
                                                                deviceInfoProvider: mockDevice,
                                                                localeProvider: DefaultLocaleProvider())
                        let result = userAgentHandler.enrichedValue(for: state)
                        
                        expect(result).to(equal("jp.co.rakuten.TestApp/ (iOS 15.0; iPhone14,2; phone; ja; Analytics/\(CoreHelpers.Constants.sdkVersion))"))
                    }
                }
                
                describe("Device Types") {
                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                    bundle.shortVersion = "1.2.3"
                    
                    let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                    
                    let deviceTypes: [(idiom: UIUserInterfaceIdiom, expectedType: String, osName: String, model: String)] = [
                        (.phone, "phone", "iOS", "iPhone14,2"),
                        (.pad, "pad", "iPadOS", "iPad13,1"),
                        (.tv, "tv", "tvOS", "AppleTV11,1"),
                        (.mac, "mac", "macOS", "Mac14,2"),
                        (.carPlay, "carPlay", "iOS", "CarPlay1,1"),
                        (.unspecified, "unspecified", "iOS", "UnknownDevice1,1")
                    ]
                    
                    func verifyDeviceType(idiom: UIUserInterfaceIdiom, expectedType: String, osName: String, model: String) {
                        it("should include '\(expectedType)' for \(osName) \(model)") {
                            let mockDevice = MockDeviceInfoProvider(
                                systemName: osName,
                                systemVersion: "15.0",
                                modelIdentifier: model,
                                userInterfaceIdiom: idiom
                            )
                            
                            let userAgentHandler = UserAgentHandler(bundle: bundle,
                                                                    deviceInfoProvider: mockDevice,
                                                                    localeProvider: DefaultLocaleProvider())
                            let result = userAgentHandler.enrichedValue(for: state)
                            
                            expect(result).toNot(beNil())
                            expect(result?.contains("; \(expectedType);")).to(beTrue())
                        }
                    }
                    
                    deviceTypes.forEach { deviceType in
                        verifyDeviceType(idiom: deviceType.idiom,
                                         expectedType: deviceType.expectedType,
                                         osName: deviceType.osName,
                                         model: deviceType.model)
                    }
                }
                
                describe("Language Handling") {
                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                    bundle.shortVersion = "1.2.3"
                    
                    context("When app language is available") {
                        it("should use the app's preferred localization") {
                            bundle.preferredLocalization = "japanese"
                            
                            let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                            
                            let mockDevice = MockDeviceInfoProvider(
                                systemName: "iOS",
                                systemVersion: "15.0",
                                modelIdentifier: "iPhone14,2",
                                userInterfaceIdiom: .phone
                            )
                            
                            let userAgentHandler = UserAgentHandler(bundle: bundle,
                                                                    deviceInfoProvider: mockDevice,
                                                                    localeProvider: DefaultLocaleProvider())
                            let result = userAgentHandler.enrichedValue(for: state)
                            
                            expect(result).to(equal("jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; ja; Analytics/\(CoreHelpers.Constants.sdkVersion))"))
                        }
                    }
                    
                    context("When system language is available but app language is not") {
                        it("should use the system language") {
                            bundle.preferredLocalization = nil
                            
                            let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                            
                            let mockDevice = MockDeviceInfoProvider(
                                systemName: "iOS",
                                systemVersion: "15.0",
                                modelIdentifier: "iPhone14,2",
                                userInterfaceIdiom: .phone
                            )
                            
                            let mockLocaleProvider = MockLocaleProvider(preferredLanguages: ["en_US", "fr_FR"])
                            
                            let userAgentHandler = UserAgentHandler(bundle: bundle,
                                                                    deviceInfoProvider: mockDevice,
                                                                    localeProvider: mockLocaleProvider)
                            let result = userAgentHandler.enrichedValue(for: state)
                            
                            expect(result).toNot(beNil())
                            expect(result).to(equal("jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; en_US; Analytics/\(CoreHelpers.Constants.sdkVersion))"))
                        }
                    }
                    
                    context("When no languages are available") {
                        it("should use the default language 'ja_JP'") {
                            bundle.preferredLocalization = nil
                            
                            let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                            
                            let mockDevice = MockDeviceInfoProvider(
                                systemName: "iOS",
                                systemVersion: "15.0",
                                modelIdentifier: "iPhone14,2",
                                userInterfaceIdiom: .phone
                            )
                            
                            let mockLocaleProvider = MockLocaleProvider(preferredLanguages: [])
                            
                            let userAgentHandler = UserAgentHandler(bundle: bundle,
                                                                    deviceInfoProvider: mockDevice,
                                                                    localeProvider: mockLocaleProvider)
                            let result = userAgentHandler.enrichedValue(for: state)
                            
                            expect(result).to(equal("jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; ja_JP; Analytics/\(CoreHelpers.Constants.sdkVersion))"))
                        }
                    }
                }
            }
        }
    }
}

