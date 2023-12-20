// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - ReferralAppModelSpec

final class ReferralAppModelSpec: QuickSpec {
    override func spec() {
        describe("ReferralAppModel") {
            #if SWIFT_PACKAGE
            let bundleIdentifier = "com.apple.dt.xctest.tool"
            #else
            let bundleIdentifier = "jp.co.rakuten.Host"
            #endif
            let encodedBundleIdentifier = bundleIdentifier.addEncodingForRFC3986UnreservedCharacters()!
            let link = "campaignCode\(CharacterSet.rfc3986ReservedCharacters)"
            let encodedLink = link.addEncodingForRFC3986UnreservedCharacters()!
            let component = "news\(CharacterSet.rfc3986ReservedCharacters)"
            let encodedComponent = component.addEncodingForRFC3986UnreservedCharacters()!
            let bundleIdentifierQueryItem = "\(PayloadParameterKeys.ref)=\(encodedBundleIdentifier)"
            let accountIdentifier: Int64 = 1
            let accountIdentifierQueryItem = "\(CpParameterKeys.Ref.accountIdentifier)=\(accountIdentifier)"
            let applicationIdentifier: Int64 = 2
            let applicationIdentifierQueryItem = "\(CpParameterKeys.Ref.applicationIdentifier)=\(applicationIdentifier)"
            let linkQueryItem = "\(CpParameterKeys.Ref.link)=\(encodedLink)"
            let componentQueryItem = "\(CpParameterKeys.Ref.component)=\(encodedComponent)"
            let mandatoryParametersQueryItems = "\(accountIdentifierQueryItem)&\(applicationIdentifierQueryItem)"
            let encodedStandardCharacters = "abcdefghijklmnopqrstuvwxyz".addEncodingForRFC3986UnreservedCharacters()!
            let encodedSpecialCharacters = CharacterSet.rfc3986ReservedCharacters.addEncodingForRFC3986UnreservedCharacters()!
            let customParameters: [String: String] = {
                var customParameters = [String: String]()
                customParameters["custom_param1"] = "japan"
                customParameters["custom_param2"] = "tokyo"
                customParameters["ref_custom_param1\(CharacterSet.rfc3986ReservedCharacters)"] = "italy\(CharacterSet.rfc3986ReservedCharacters)"
                customParameters["ref_custom_param2\(CharacterSet.rfc3986ReservedCharacters)"] = "rome\(CharacterSet.rfc3986ReservedCharacters)"
                return customParameters
            }()
            let model = ReferralAppModel(bundleIdentifier: bundleIdentifier,
                                         accountIdentifier: accountIdentifier,
                                         applicationIdentifier: applicationIdentifier,
                                         link: link,
                                         component: component,
                                         customParameters: customParameters)

            describe("init(bundleIdentifier:accountIdentifier:applicationIdentifier:link:component:customParameters:)") {
                context("Initialization with mandatory parameters") {
                    it("should be initialized with expected values") {
                        let model = ReferralAppModel(bundleIdentifier: bundleIdentifier,
                                                     accountIdentifier: 1,
                                                     applicationIdentifier: 2,
                                                     link: nil,
                                                     component: nil,
                                                     customParameters: [:])

                        expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                        expect(model.accountIdentifier).to(equal(1))
                        expect(model.applicationIdentifier).to(equal(2))
                        expect(model.link).to(beNil())
                        expect(model.component).to(beNil())
                        expect(model.customParameters).to(equal([:]))
                    }
                }

                context("Initialization with mandatory and optional parameters") {
                    it("should be initialized with expected values") {
                        let model = ReferralAppModel(bundleIdentifier: bundleIdentifier,
                                                     accountIdentifier: 1,
                                                     applicationIdentifier: 2,
                                                     link: link,
                                                     component: component,
                                                     customParameters: ["key1": "value1"])

                        expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                        expect(model.accountIdentifier).to(equal(1))
                        expect(model.applicationIdentifier).to(equal(2))
                        expect(model.link).to(equal(link))
                        expect(model.component).to(equal(component))
                        expect(model.customParameters).to(equal(["key1": "value1"]))
                    }
                }
            }

            describe("init(url:sourceApplication:)") {
                it("should fail when mandatory parameters are missing") {
                    // URL Scheme
                    expect(ReferralAppModel(url: URL(string: "app://")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "app://?\(accountIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "app://?\(applicationIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())

                    // Universal Link
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp")!, sourceApplication: nil)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)")!, sourceApplication: nil)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(accountIdentifierQueryItem)")!, sourceApplication: nil)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(applicationIdentifierQueryItem)")!, sourceApplication: nil)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(accountIdentifierQueryItem)")!, sourceApplication: nil)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(applicationIdentifierQueryItem)")!, sourceApplication: nil)).to(beNil())
                }

                it("should fail when mandatory parameters are unexpected") {
                    // URL Scheme
                    expect(ReferralAppModel(url: URL(string: "app://\(CpParameterKeys.Ref.accountIdentifier)=\(encodedStandardCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(encodedStandardCharacters)")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "app://\(CpParameterKeys.Ref.accountIdentifier)=\(encodedSpecialCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(encodedSpecialCharacters)")!, sourceApplication: bundleIdentifier)).to(beNil())

                    // Universal Link
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(CpParameterKeys.Ref.accountIdentifier)=\(encodedStandardCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(encodedStandardCharacters)")!, sourceApplication: nil)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(CpParameterKeys.Ref.accountIdentifier)=\(encodedSpecialCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(encodedSpecialCharacters)")!, sourceApplication: nil)).to(beNil())
                }

                context("Initialization with mandatory parameters") {
                    context("When url is URL scheme") {
                        let appURL: URL! = URL(string: "app://?\(mandatoryParametersQueryItems)")
                        let model: ReferralAppModel! = ReferralAppModel(url: appURL, sourceApplication: bundleIdentifier)

                        it("should set an expected bundle identifier") {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                        }

                        it("should set an expected account identifier") {
                            expect(model.accountIdentifier).to(equal(1))
                        }

                        it("should set an expected application identifier") {
                            expect(model.applicationIdentifier).to(equal(2))
                        }

                        it("should set a nil link") {
                            expect(model.link).to(beNil())
                        }

                        it("should set a nil component") {
                            expect(model.component).to(beNil())
                        }

                        it("should set an empty custom parameters") {
                            expect(model.customParameters).to(equal([:]))
                        }
                    }

                    context("When url is universal link") {
                        let universalLinkURL: URL! = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(mandatoryParametersQueryItems)")
                        let model: ReferralAppModel! = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)

                        it("should set an expected bundle identifier") {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                        }

                        it("should set an expected account identifier") {
                            expect(model.accountIdentifier).to(equal(1))
                        }

                        it("should set an expected application identifier") {
                            expect(model.applicationIdentifier).to(equal(2))
                        }

                        it("should set a nil link") {
                            expect(model.link).to(beNil())
                        }

                        it("should set a nil component") {
                            expect(model.component).to(beNil())
                        }

                        it("should set an empty custom parameters") {
                            expect(model.customParameters).to(equal([:]))
                        }
                    }
                }

                context("Initialization with mandatory and optional parameters") {
                    var customParameters = [String: String]()
                    var encodedCustomParameters = [String: String]()

                    afterEach {
                        customParameters.removeAll()
                        encodedCustomParameters.removeAll()
                    }

                    context("Only a link is provided") {
                        it("should be initialized with expected values") {
                            let commonParameters = "\(mandatoryParametersQueryItems)&\(linkQueryItem)"
                            let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: bundleIdentifier)!
                            verify(model: appModel)
                            let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                            let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                            verify(model: universalModel)
                        }

                        func verify(model: ReferralAppModel) {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal(link))
                            expect(model.component).to(beNil())
                            expect(model.customParameters).to(equal([:]))
                        }
                    }

                    context("Only a component is provided") {
                        it("should be initialized with expected values") {
                            let commonParameters = "\(mandatoryParametersQueryItems)&\(componentQueryItem)"
                            let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!,
                                                            sourceApplication: bundleIdentifier)!
                            verify(model: appModel)
                            let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                            let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                            verify(model: universalModel)
                        }

                        func verify(model: ReferralAppModel) {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(beNil())
                            expect(model.component).to(equal(component))
                            expect(model.customParameters).to(equal([:]))
                        }
                    }

                    context("Only custom parameters are provided") {
                        it("should be initialized with expected values") {
                            (0...5).forEach { index in
                                let key = "key\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                                let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!

                                customParameters[key] = value

                                encodedCustomParameters[encodedKey] = encodedValue

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(encodedCustomParameters.toRQuery)"

                                let url = URL(string: "app://?\(commonParameters)")!
                                let appModel = ReferralAppModel(url: url, sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)
                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(beNil())
                            expect(model.component).to(beNil())
                            expect(model.customParameters).to(equal(customParameters))
                        }
                    }

                    context("Only a link and a component are provided") {
                        it("should be initialized with expected values") {
                            let commonParameters = "\(mandatoryParametersQueryItems)&\(linkQueryItem)&\(componentQueryItem)"

                            let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: bundleIdentifier)!
                            verify(model: appModel)
                            let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                            let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                            verify(model: universalModel)
                        }

                        func verify(model: ReferralAppModel) {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal(link))
                            expect(model.component).to(equal(component))
                            expect(model.customParameters).to(equal([:]))
                        }
                    }

                    context("Only a link and custom parameters are provided") {
                        context("custom params start with ref_") {
                            verifyCustomParams(key: "ref_key")
                        }

                        context("custom params does not start with ref_") {
                            it("should be initialized with expected values") {
                                verifyCustomParams(key: "key")
                            }
                        }

                        func verifyCustomParams(key: String) {
                            (0...5).forEach { index in
                                let key = "\(key)\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                                let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!

                                customParameters[key] = value

                                encodedCustomParameters[encodedKey] = encodedValue

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(linkQueryItem)&\(encodedCustomParameters.toRQuery)"

                                let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)
                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal(link))
                            expect(model.component).to(beNil())
                            expect(model.customParameters).to(equal(customParameters))
                        }
                    }

                    context("Only a component and custom parameters are provided") {
                        context("custom params start with ref_") {
                            it("should be initialized with expected values") {
                                verifyCustomParams(key: "ref_key")
                            }
                        }

                        context("custom params does not start with ref_") {
                            it("should be initialized with expected values") {
                                verifyCustomParams(key: "key")
                            }
                        }

                        func verifyCustomParams(key: String) {
                            (0...5).forEach { index in
                                let key = "\(key)\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                                let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!

                                customParameters[key] = value

                                encodedCustomParameters[encodedKey] = encodedValue

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(componentQueryItem)&\(encodedCustomParameters.toRQuery)"

                                let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!,
                                                                sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)
                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(beNil())
                            expect(model.component).to(equal(component))
                            expect(model.customParameters).to(equal(customParameters))
                        }
                    }

                    context("Link, component and custom parameters are provided") {
                        context("custom params start with ref_") {
                            it("should be initialized with expected values") {
                                verifyCustomParams(key: "ref_key")
                            }
                        }

                        context("custom params does not start with ref_") {
                            it("should be initialized with expected values") {
                                verifyCustomParams(key: "key")
                            }
                        }

                        func verifyCustomParams(key: String) {
                            (0...5).forEach { index in
                                let key = "\(key)\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                                let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                                let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!

                                customParameters[key] = value

                                encodedCustomParameters[encodedKey] = encodedValue

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(linkQueryItem)&\(componentQueryItem)&\(encodedCustomParameters.toRQuery)"

                                let appURL = URL(string: "app://?\(commonParameters)")!
                                let appModel = ReferralAppModel(url: appURL, sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)
                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal(bundleIdentifier))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal(link))
                            expect(model.component).to(equal(component))
                            expect(model.customParameters).to(equal(customParameters))
                        }
                    }
                }
            }

            describe("init(link:component:customParameters:)") {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = bundleIdentifier

                context("When bundleIdentifier is nil") {
                    it("should return nil") {
                        let bundle = BundleMock()
                        bundle.bundleIdentifier = nil
                        let model = ReferralAppModel(bundle: bundle)
                        expect(model).to(beNil())
                    }
                }

                context("When bundleIdentifier is not nil") {
                    context("When RAT identifiers are configured") {
                        it("should return expected url scheme with minimal non-optional parameters") {
                            let model = ReferralAppModel(bundle: bundle)

                            expect(model?.urlScheme(appScheme: "app")?.absoluteString).to(equal("app://?ref_acc=477&ref_aid=1"))
                        }

                        it("should return expected universal link with minimal non-optional parameters") {
                            let model = ReferralAppModel(bundle: bundle)
                            expect(model?.universalLink(domain: "rakuten.co.jp")?.absoluteString).to(equal("https://rakuten.co.jp?ref=\(bundleIdentifier)&ref_acc=477&ref_aid=1"))
                        }
                    }

                    context("When RAT identifiers are not configured") {
                        it("should return expected url scheme with RAT identifiers set to 0 and minimal non-optional parameters") {
                            let model = ReferralAppModel()

                            expect(model?.urlScheme(appScheme: "app")?.absoluteString).to(equal("app://?ref_acc=0&ref_aid=0"))
                        }

                        it("should return expected universal link with RAT identifiers set to 0 and minimal non-optional parameters") {
                            let model = ReferralAppModel()
                            expect(model?.universalLink(domain: "rakuten.co.jp")?.absoluteString).to(equal("https://rakuten.co.jp?ref=\(bundleIdentifier)&ref_acc=0&ref_aid=0"))
                        }
                    }
                }

                context("When RAT identifiers are configured") {
                    let model = ReferralAppModel(link: link,
                                                 component: component,
                                                 customParameters: customParameters,
                                                 bundle: bundle)

                    it("should return expected url scheme with all expected parameters") {
                        let urlScheme = model?.urlScheme(appScheme: "app")?.absoluteString
                        expect(urlScheme?.starts(with: "app://?ref_acc=477&ref_aid=1&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                        expect(urlScheme?.contains("custom_param1=japan")).to(beTrue())
                        expect(urlScheme?.contains("custom_param2=tokyo")).to(beTrue())
                        expect(urlScheme?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                        expect(urlScheme?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    }

                    it("should return expected universal link with all expected parameters") {
                        let universalLink = model?.universalLink(domain: "rakuten.co.jp")?.absoluteString
                        expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(bundleIdentifier)&ref_acc=477&ref_aid=1&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())

                        expect(universalLink?.contains("custom_param1=japan")).to(beTrue())
                        expect(universalLink?.contains("custom_param2=tokyo")).to(beTrue())
                        expect(universalLink?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                        expect(universalLink?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    }
                }

                context("When RAT identifiers are not configured") {
                    let model = ReferralAppModel(link: link,
                                                 component: component,
                                                 customParameters: customParameters,
                                                 bundle: Bundle.main)

                    it("should return expected url scheme with RAT identifiers set to 0 and all expected parameters") {
                        let urlScheme = model?.urlScheme(appScheme: "app")?.absoluteString
                        expect(urlScheme?.starts(with: "app://?ref_acc=0&ref_aid=0&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                        expect(urlScheme?.contains("custom_param1=japan")).to(beTrue())
                        expect(urlScheme?.contains("custom_param2=tokyo")).to(beTrue())
                        expect(urlScheme?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                        expect(urlScheme?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    }

                    it("should return expected universal link with RAT identifiers set to 0 and all expected parameters") {
                        let universalLink = model?.universalLink(domain: "rakuten.co.jp")?.absoluteString
                        expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(bundleIdentifier)&ref_acc=0&ref_aid=0&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())

                        expect(universalLink?.contains("custom_param1=japan")).to(beTrue())
                        expect(universalLink?.contains("custom_param2=tokyo")).to(beTrue())
                        expect(universalLink?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                        expect(universalLink?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    }
                }
            }

            describe("init(accountIdentifier:applicationIdentifier:link:component:customParameters:)") {
                it("should return nil when bundleIdentifier is nil") {
                    let bundle = BundleMock()
                    bundle.bundleIdentifier = nil
                    let model = ReferralAppModel(accountIdentifier: accountIdentifier,
                                                 applicationIdentifier: applicationIdentifier,
                                                 bundle: bundle)
                    expect(model).to(beNil())
                }

                it("should return expected url scheme and expected universal link with minimal non-optional parameters") {
                    let model = ReferralAppModel(accountIdentifier: accountIdentifier,
                                                 applicationIdentifier: applicationIdentifier)
                    expect(model?.urlScheme(appScheme: "app")?.absoluteString).to(equal("app://?ref_acc=1&ref_aid=2"))
                    expect(model?.universalLink(domain: "rakuten.co.jp")?.absoluteString).to(equal("https://rakuten.co.jp?ref=\(bundleIdentifier)&ref_acc=1&ref_aid=2"))
                }

                it("should return expected url scheme and expected universal link with all parameters") {
                    let model = ReferralAppModel(accountIdentifier: accountIdentifier,
                                                 applicationIdentifier: applicationIdentifier,
                                                 link: link,
                                                 component: component,
                                                 customParameters: customParameters,
                                                 bundle: Bundle.main)
                    let urlScheme = model?.urlScheme(appScheme: "app")?.absoluteString
                    expect(urlScheme?.starts(with: "app://?ref_acc=1&ref_aid=2&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(urlScheme?.contains("custom_param1=japan")).to(beTrue())
                    expect(urlScheme?.contains("custom_param2=tokyo")).to(beTrue())
                    expect(urlScheme?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(urlScheme?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())

                    let universalLink = model?.universalLink(domain: "rakuten.co.jp")?.absoluteString
                    expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(bundleIdentifier)&ref_acc=1&ref_aid=2&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(universalLink?.contains("custom_param1=japan")).to(beTrue())
                    expect(universalLink?.contains("custom_param2=tokyo")).to(beTrue())
                    expect(universalLink?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(universalLink?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                }
            }

            describe("urlScheme(appScheme:)") {
                it("should return nil if the app scheme is empty") {
                    let urlScheme = model.urlScheme(appScheme: "")?.absoluteString
                    expect(urlScheme).to(beNil())
                }

                it("should return the expected URL") {
                    let urlScheme = model.urlScheme(appScheme: "app")?.absoluteString

                    expect(urlScheme?.starts(with: "app://?ref_acc=1&ref_aid=2&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())

                    expect(urlScheme?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(urlScheme?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(urlScheme?.contains("custom_param1=japan")).to(beTrue())
                    expect(urlScheme?.contains("custom_param2=tokyo")).to(beTrue())
                }
            }

            describe("universalLink(domain:)") {
                it("should return nil if the domain is empty") {
                    let universalLink = model.universalLink(domain: "")?.absoluteString
                    expect(universalLink).to(beNil())
                }

                it("should return the expected URL") {
                    let universalLink = model.universalLink(domain: "rakuten.co.jp")?.absoluteString
                    expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(bundleIdentifier)&ref_acc=1&ref_aid=2&ref_link=campaignCode%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D&ref_comp=news%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())

                    expect(universalLink?.contains("ref_custom_param1%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=italy%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(universalLink?.contains("ref_custom_param2%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D=rome%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D")).to(beTrue())
                    expect(universalLink?.contains("custom_param1=japan")).to(beTrue())
                    expect(universalLink?.contains("custom_param2=tokyo")).to(beTrue())
                }
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
