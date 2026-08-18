// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - ReferralAppModelTests

@Suite("ReferralAppModel")
struct ReferralAppModelTests {
    #if SWIFT_PACKAGE
    static let bundleIdentifier = "com.apple.dt.xctest.tool"
    #else
    static let bundleIdentifier = "jp.co.rakuten.Host"
    #endif
    
    static let encodedBundleIdentifier = bundleIdentifier.addEncodingForRFC3986UnreservedCharacters()!
    static let link = "campaignCode\(CharacterSet.rfc3986ReservedCharacters)"
    static let encodedLink = link.addEncodingForRFC3986UnreservedCharacters()!
    static let component = "news\(CharacterSet.rfc3986ReservedCharacters)"
    static let encodedComponent = component.addEncodingForRFC3986UnreservedCharacters()!
    static let bundleIdentifierQueryItem = "\(PayloadParameterKeys.ref)=\(encodedBundleIdentifier)"
    static let accountIdentifier: Int64 = 1
    static let accountIdentifierQueryItem = "\(CpParameterKeys.Ref.accountIdentifier)=\(accountIdentifier)"
    static let applicationIdentifier: Int64 = 2
    static let applicationIdentifierQueryItem = "\(CpParameterKeys.Ref.applicationIdentifier)=\(applicationIdentifier)"
    static let linkQueryItem = "\(CpParameterKeys.Ref.link)=\(encodedLink)"
    static let componentQueryItem = "\(CpParameterKeys.Ref.component)=\(encodedComponent)"
    static let mandatoryParametersQueryItems = "\(accountIdentifierQueryItem)&\(applicationIdentifierQueryItem)"
    static let encodedStandardCharacters = "abcdefghijklmnopqrstuvwxyz".addEncodingForRFC3986UnreservedCharacters()!
    static let encodedSpecialCharacters = CharacterSet.rfc3986ReservedCharacters.addEncodingForRFC3986UnreservedCharacters()!
    static let customParameters: [String: String] = {
        var customParameters = [String: String]()
        customParameters["custom_param1"] = "japan"
        customParameters["custom_param2"] = "tokyo"
        customParameters["ref_custom_param1\(CharacterSet.rfc3986ReservedCharacters)"] = "italy\(CharacterSet.rfc3986ReservedCharacters)"
        customParameters["ref_custom_param2\(CharacterSet.rfc3986ReservedCharacters)"] = "rome\(CharacterSet.rfc3986ReservedCharacters)"
        return customParameters
    }()
    
    static let refCustomParamItaly = "ref_custom_param1%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D=italy%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D"
    static let refCustomParamRome = "ref_custom_param2%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D=rome%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D"
    
    static let model = ReferralAppModel(bundleIdentifier: bundleIdentifier,
                                        accountIdentifier: accountIdentifier,
                                        applicationIdentifier: applicationIdentifier,
                                        link: link,
                                        component: component,
                                        customParameters: customParameters)
    
    @Suite("init(bundleIdentifier:accountIdentifier:applicationIdentifier:link:component:customParameters:)")
    struct InitBundleIdentifierTests {
        @Suite("Initialization with mandatory parameters")
        struct MandatoryParametersTests {
            @Test("should be initialized with expected values")
            func testShouldBeInitializedWithExpectedValues() {
                let model = ReferralAppModel(bundleIdentifier: ReferralAppModelTests.bundleIdentifier,
                                             accountIdentifier: 1,
                                             applicationIdentifier: 2,
                                             link: nil,
                                             component: nil,
                                             customParameters: [:])
                
                #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                #expect(model.accountIdentifier == 1)
                #expect(model.applicationIdentifier == 2)
                #expect(model.link == nil)
                #expect(model.component == nil)
                #expect(model.customParameters == [:])
            }
        }
        
        @Suite("Initialization with mandatory and optional parameters")
        struct MandatoryAndOptionalParametersTests {
            @Test("should be initialized with expected values")
            func testShouldBeInitializedWithExpectedValues() {
                let model = ReferralAppModel(bundleIdentifier: ReferralAppModelTests.bundleIdentifier,
                                             accountIdentifier: 1,
                                             applicationIdentifier: 2,
                                             link: ReferralAppModelTests.link,
                                             component: ReferralAppModelTests.component,
                                             customParameters: ["key1": "value1"])
                
                #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                #expect(model.accountIdentifier == 1)
                #expect(model.applicationIdentifier == 2)
                #expect(model.link == ReferralAppModelTests.link)
                #expect(model.component == ReferralAppModelTests.component)
                #expect(model.customParameters == ["key1": "value1"])
            }
        }
    }
    
    @Suite("init(url:sourceApplication:)")
    struct InitURLTests {
        @Test("should fail when mandatory parameters are missing")
        func testShouldFailWhenMandatoryParametersAreMissing() {
            // URL Scheme
            #expect(ReferralAppModel(url: URL(string: "app://")!, sourceApplication: ReferralAppModelTests.bundleIdentifier) == nil)
            #expect(ReferralAppModel(url: URL(string: "app://?\(ReferralAppModelTests.accountIdentifierQueryItem)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier) == nil)
            #expect(ReferralAppModel(url: URL(string: "app://?\(ReferralAppModelTests.applicationIdentifierQueryItem)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier) == nil)
            
            // Universal Link
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp")!, sourceApplication: nil) == nil)
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)")!, sourceApplication: nil) == nil)
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.accountIdentifierQueryItem)")!, sourceApplication: nil) == nil)
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.applicationIdentifierQueryItem)")!, sourceApplication: nil) == nil)
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(ReferralAppModelTests.accountIdentifierQueryItem)")!, sourceApplication: nil) == nil)
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(ReferralAppModelTests.applicationIdentifierQueryItem)")!, sourceApplication: nil) == nil)
        }
        
        @Test("should fail when mandatory parameters are unexpected")
        func testShouldFailWhenMandatoryParametersAreUnexpected() {
            // URL Scheme
            #expect(ReferralAppModel(url: URL(string: "app://\(CpParameterKeys.Ref.accountIdentifier)=\(ReferralAppModelTests.encodedStandardCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(ReferralAppModelTests.encodedStandardCharacters)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier) == nil)
            #expect(ReferralAppModel(url: URL(string: "app://\(CpParameterKeys.Ref.accountIdentifier)=\(ReferralAppModelTests.encodedSpecialCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(ReferralAppModelTests.encodedSpecialCharacters)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier) == nil)
            
            // Universal Link
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(CpParameterKeys.Ref.accountIdentifier)=\(ReferralAppModelTests.encodedStandardCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(ReferralAppModelTests.encodedStandardCharacters)")!, sourceApplication: nil) == nil)
            #expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(CpParameterKeys.Ref.accountIdentifier)=\(ReferralAppModelTests.encodedSpecialCharacters)&\(CpParameterKeys.Ref.applicationIdentifier)=\(ReferralAppModelTests.encodedSpecialCharacters)")!, sourceApplication: nil) == nil)
        }
        
        @Suite("Initialization with mandatory parameters")
        struct MandatoryParametersTests {
            @Suite("When url is URL scheme")
            struct URLSchemeTests {
                static let appURL = URL(string: "app://?\(ReferralAppModelTests.mandatoryParametersQueryItems)")!
                static let model = ReferralAppModel(url: appURL, sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                
                @Test("should set an expected bundle identifier")
                func testShouldSetExpectedBundleIdentifier() {
                    #expect(URLSchemeTests.model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                }
                
                @Test("should set an expected account identifier")
                func testShouldSetExpectedAccountIdentifier() {
                    #expect(URLSchemeTests.model.accountIdentifier == 1)
                }
                
                @Test("should set an expected application identifier")
                func testShouldSetExpectedApplicationIdentifier() {
                    #expect(URLSchemeTests.model.applicationIdentifier == 2)
                }
                
                @Test("should set a nil link")
                func testShouldSetNilLink() {
                    #expect(URLSchemeTests.model.link == nil)
                }
                
                @Test("should set a nil component")
                func testShouldSetNilComponent() {
                    #expect(URLSchemeTests.model.component == nil)
                }
                
                @Test("should set an empty custom parameters")
                func testShouldSetEmptyCustomParameters() {
                    #expect(URLSchemeTests.model.customParameters == [:])
                }
            }
            
            @Suite("When url is universal link")
            struct UniversalLinkTests {
                static let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(ReferralAppModelTests.mandatoryParametersQueryItems)")!
                static let model = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                
                @Test("should set an expected bundle identifier")
                func testShouldSetExpectedBundleIdentifier() {
                    #expect(UniversalLinkTests.model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                }
                
                @Test("should set an expected account identifier")
                func testShouldSetExpectedAccountIdentifier() {
                    #expect(UniversalLinkTests.model.accountIdentifier == 1)
                }
                
                @Test("should set an expected application identifier")
                func testShouldSetExpectedApplicationIdentifier() {
                    #expect(UniversalLinkTests.model.applicationIdentifier == 2)
                }
                
                @Test("should set a nil link")
                func testShouldSetNilLink() {
                    #expect(UniversalLinkTests.model.link == nil)
                }
                
                @Test("should set a nil component")
                func testShouldSetNilComponent() {
                    #expect(UniversalLinkTests.model.component == nil)
                }
                
                @Test("should set an empty custom parameters")
                func testShouldSetEmptyCustomParameters() {
                    #expect(UniversalLinkTests.model.customParameters == [:])
                }
            }
        }
        
        @Suite("Initialization with mandatory and optional parameters")
        struct MandatoryAndOptionalParametersTests {
            @Suite("Only a link is provided")
            struct OnlyLinkTests {
                @Test("should be initialized with expected values")
                func testShouldBeInitializedWithExpectedValues() {
                    let commonParameters = "\(ReferralAppModelTests.mandatoryParametersQueryItems)&\(ReferralAppModelTests.linkQueryItem)"
                    let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                    OnlyLinkTests.verify(model: appModel)
                    let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(commonParameters)")!
                    let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                    OnlyLinkTests.verify(model: universalModel)
                }
                
                static func verify(model: ReferralAppModel) {
                    #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                    #expect(model.accountIdentifier == 1)
                    #expect(model.applicationIdentifier == 2)
                    #expect(model.link == ReferralAppModelTests.link)
                    #expect(model.component == nil)
                    #expect(model.customParameters == [:])
                }
            }
            
            @Suite("Only a component is provided")
            struct OnlyComponentTests {
                @Test("should be initialized with expected values")
                func testShouldBeInitializedWithExpectedValues() {
                    let commonParameters = "\(ReferralAppModelTests.mandatoryParametersQueryItems)&\(ReferralAppModelTests.componentQueryItem)"
                    let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!,
                                                    sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                    OnlyComponentTests.verify(model: appModel)
                    let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(commonParameters)")!
                    let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                    OnlyComponentTests.verify(model: universalModel)
                }
                
                static func verify(model: ReferralAppModel) {
                    #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                    #expect(model.accountIdentifier == 1)
                    #expect(model.applicationIdentifier == 2)
                    #expect(model.link == nil)
                    #expect(model.component == ReferralAppModelTests.component)
                    #expect(model.customParameters == [:])
                }
            }
            
            @Suite("Only custom parameters are provided")
            struct OnlyCustomParametersTests {
                @Test("should be initialized with expected values")
                func testShouldBeInitializedWithExpectedValues() {
                    var customParameters = [String: String]()
                    var encodedCustomParameters = [String: String]()
                    defer {
                        customParameters.removeAll()
                        encodedCustomParameters.removeAll()
                    }
                    
                    (0...5).forEach { index in
                        let key = "key\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                        let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!
                        
                        customParameters[key] = value
                        
                        encodedCustomParameters[encodedKey] = encodedValue
                        
                        let commonParameters = "\(ReferralAppModelTests.mandatoryParametersQueryItems)&\(encodedCustomParameters.toRQuery)"
                        
                        let url = URL(string: "app://?\(commonParameters)")!
                        let appModel = ReferralAppModel(url: url, sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                        OnlyCustomParametersTests.verify(model: appModel, customParameters: customParameters)
                        let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(commonParameters)")!
                        let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                        OnlyCustomParametersTests.verify(model: universalModel, customParameters: customParameters)
                    }
                }
                
                static func verify(model: ReferralAppModel, customParameters: [String: String]) {
                    #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                    #expect(model.accountIdentifier == 1)
                    #expect(model.applicationIdentifier == 2)
                    #expect(model.link == nil)
                    #expect(model.component == nil)
                    #expect(model.customParameters == customParameters)
                }
            }
            
            @Suite("Only a link and a component are provided")
            struct LinkAndComponentTests {
                @Test("should be initialized with expected values")
                func testShouldBeInitializedWithExpectedValues() {
                    let commonParameters = "\(ReferralAppModelTests.mandatoryParametersQueryItems)&\(ReferralAppModelTests.linkQueryItem)&\(ReferralAppModelTests.componentQueryItem)"
                    
                    let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                    LinkAndComponentTests.verify(model: appModel)
                    let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(commonParameters)")!
                    let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                    LinkAndComponentTests.verify(model: universalModel)
                }
                
                static func verify(model: ReferralAppModel) {
                    #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                    #expect(model.accountIdentifier == 1)
                    #expect(model.applicationIdentifier == 2)
                    #expect(model.link == ReferralAppModelTests.link)
                    #expect(model.component == ReferralAppModelTests.component)
                    #expect(model.customParameters == [:])
                }
            }
            
            @Suite("Only a link and custom parameters are provided")
            struct LinkAndCustomParametersTests {
                @Suite("custom params start with ref_")
                struct CustomParamsStartWithRefTests {
                    @Test("should be initialized with expected values")
                    func testShouldBeInitializedWithExpectedValues() {
                        LinkAndCustomParametersTests.verifyCustomParams(key: "ref_key")
                    }
                }
                
                @Suite("custom params does not start with ref_")
                struct CustomParamsDoNotStartWithRefTests {
                    @Test("should be initialized with expected values")
                    func testShouldBeInitializedWithExpectedValues() {
                        LinkAndCustomParametersTests.verifyCustomParams(key: "key")
                    }
                }
                
                static func verifyCustomParams(key: String) {
                    var customParameters = [String: String]()
                    var encodedCustomParameters = [String: String]()
                    defer {
                        customParameters.removeAll()
                        encodedCustomParameters.removeAll()
                    }
                    
                    (0...5).forEach { index in
                        let key = "\(key)\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                        let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!
                        
                        customParameters[key] = value
                        
                        encodedCustomParameters[encodedKey] = encodedValue
                        
                        let commonParameters = "\(ReferralAppModelTests.mandatoryParametersQueryItems)&\(ReferralAppModelTests.linkQueryItem)&\(encodedCustomParameters.toRQuery)"
                        
                        let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                        LinkAndCustomParametersTests.verify(model: appModel, customParameters: customParameters)
                        let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(commonParameters)")!
                        let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                        LinkAndCustomParametersTests.verify(model: universalModel, customParameters: customParameters)
                    }
                }
                
                static func verify(model: ReferralAppModel, customParameters: [String: String]) {
                    #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                    #expect(model.accountIdentifier == 1)
                    #expect(model.applicationIdentifier == 2)
                    #expect(model.link == ReferralAppModelTests.link)
                    #expect(model.component == nil)
                    #expect(model.customParameters == customParameters)
                }
            }
            
            @Suite("Only a component and custom parameters are provided")
            struct ComponentAndCustomParametersTests {
                @Suite("custom params start with ref_")
                struct CustomParamsStartWithRefTests {
                    @Test("should be initialized with expected values")
                    func testShouldBeInitializedWithExpectedValues() {
                        ComponentAndCustomParametersTests.verifyCustomParams(key: "ref_key")
                    }
                }
                
                @Suite("custom params does not start with ref_")
                struct CustomParamsDoNotStartWithRefTests {
                    @Test("should be initialized with expected values")
                    func testShouldBeInitializedWithExpectedValues() {
                        ComponentAndCustomParametersTests.verifyCustomParams(key: "key")
                    }
                }
                
                static func verifyCustomParams(key: String) {
                    var customParameters = [String: String]()
                    var encodedCustomParameters = [String: String]()
                    defer {
                        customParameters.removeAll()
                        encodedCustomParameters.removeAll()
                    }
                    
                    (0...5).forEach { index in
                        let key = "\(key)\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                        let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!
                        
                        customParameters[key] = value
                        encodedCustomParameters[encodedKey] = encodedValue
                        
                        let commonParameters = "\(ReferralAppModelTests.mandatoryParametersQueryItems)&\(ReferralAppModelTests.componentQueryItem)&\(encodedCustomParameters.toRQuery)"
                        let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                        ComponentAndCustomParametersTests.verify(model: appModel, customParameters: customParameters)
                        let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(commonParameters)")!
                        let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                        ComponentAndCustomParametersTests.verify(model: universalModel, customParameters: customParameters)
                    }
                }
                
                static func verify(model: ReferralAppModel, customParameters: [String: String]) {
                    #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                    #expect(model.accountIdentifier == 1)
                    #expect(model.applicationIdentifier == 2)
                    #expect(model.link == nil)
                    #expect(model.component == ReferralAppModelTests.component)
                    #expect(model.customParameters == customParameters)
                }
            }
            
            @Suite("Link, component and custom parameters are provided")
            struct LinkComponentAndCustomParametersTests {
                @Suite("custom params start with ref_")
                struct CustomParamsStartWithRefTests {
                    @Test("should be initialized with expected values")
                    func testShouldBeInitializedWithExpectedValues() {
                        LinkComponentAndCustomParametersTests.verifyCustomParams(key: "ref_key")
                    }
                }
                
                @Suite("custom params does not start with ref_")
                struct CustomParamsDoNotStartWithRefTests {
                    @Test("should be initialized with expected values")
                    func testShouldBeInitializedWithExpectedValues() {
                        LinkComponentAndCustomParametersTests.verifyCustomParams(key: "key")
                    }
                }
                
                static func verifyCustomParams(key: String) {
                    var customParameters = [String: String]()
                    var encodedCustomParameters = [String: String]()
                    defer {
                        customParameters.removeAll()
                        encodedCustomParameters.removeAll()
                    }
                    
                    (0...5).forEach { index in
                        let key = "\(key)\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedKey = key.addEncodingForRFC3986UnreservedCharacters()!
                        let value = "value\(CharacterSet.rfc3986ReservedCharacters)\(index)"
                        let encodedValue = value.addEncodingForRFC3986UnreservedCharacters()!
                        
                        customParameters[key] = value
                        encodedCustomParameters[encodedKey] = encodedValue
                        
                        let commonParameters = "\(ReferralAppModelTests.mandatoryParametersQueryItems)&\(ReferralAppModelTests.linkQueryItem)&\(ReferralAppModelTests.componentQueryItem)&\(encodedCustomParameters.toRQuery)"
                        
                        let appURL = URL(string: "app://?\(commonParameters)")!
                        let appModel = ReferralAppModel(url: appURL, sourceApplication: ReferralAppModelTests.bundleIdentifier)!
                        LinkComponentAndCustomParametersTests.verify(model: appModel, customParameters: customParameters)
                        let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(ReferralAppModelTests.bundleIdentifierQueryItem)&\(commonParameters)")!
                        let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: nil)!
                        LinkComponentAndCustomParametersTests.verify(model: universalModel, customParameters: customParameters)
                    }
                }
                
                static func verify(model: ReferralAppModel, customParameters: [String: String]) {
                    #expect(model.bundleIdentifier == ReferralAppModelTests.bundleIdentifier)
                    #expect(model.accountIdentifier == 1)
                    #expect(model.applicationIdentifier == 2)
                    #expect(model.link == ReferralAppModelTests.link)
                    #expect(model.component == ReferralAppModelTests.component)
                    #expect(model.customParameters == customParameters)
                }
            }
        }
    }
    
    @Suite("init(link:component:customParameters:)")
    struct InitLinkComponentCustomParametersTests {
        static let bundle: BundleMock = {
            let bundle = BundleMock.create()
            bundle.bundleIdentifier = ReferralAppModelTests.bundleIdentifier
            return bundle
        }()
        
        @Suite("When bundleIdentifier is nil")
        struct BundleIdentifierNilTests {
            @Test("should return nil")
            func testShouldReturnNil() {
                let bundle = BundleMock()
                bundle.bundleIdentifier = nil
                let model = ReferralAppModel(bundle: bundle)
                #expect(model == nil)
            }
        }
        
        @Suite("When bundleIdentifier is not nil")
        struct BundleIdentifierNotNilTests {
            @Suite("When RAT identifiers are configured")
            struct RATIdentifiersConfiguredTests {
                @Test("should return expected url scheme with minimal non-optional parameters")
                func testShouldReturnExpectedUrlScheme() {
                    let model = ReferralAppModel(bundle: InitLinkComponentCustomParametersTests.bundle)
                    #expect(model?.urlScheme(appScheme: "app")?.absoluteString == "app://?ref=jp.co.rakuten.Host&ref_acc=477&ref_aid=1")
                }
                
                @Test("should return expected universal link with minimal non-optional parameters")
                func testShouldReturnExpectedUniversalLink() {
                    let model = ReferralAppModel(bundle: InitLinkComponentCustomParametersTests.bundle)
                    #expect(model?.universalLink(domain: "rakuten.co.jp")?.absoluteString == "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=477&ref_aid=1")
                }
            }
            
            @Suite("When RAT identifiers are not configured")
            struct RATIdentifiersNotConfiguredTests {
                @Test("should return expected url scheme with RAT identifiers set to 1 and minimal non-optional parameters")
                func testShouldReturnExpectedUrlScheme() {
                    let model = ReferralAppModel()
                    #expect(model?.urlScheme(appScheme: "app")?.absoluteString == "app://?ref=jp.co.rakuten.Host&ref_acc=0&ref_aid=1")
                }
                
                @Test("should return expected universal link with RAT identifiers set to 1 and minimal non-optional parameters")
                func testShouldReturnExpectedUniversalLink() {
                    let model = ReferralAppModel()
                    #expect(model?.universalLink(domain: "rakuten.co.jp")?.absoluteString == "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=0&ref_aid=1")
                }
            }
        }
        
        @Suite("When RAT identifiers are configured")
        struct RATIdentifiersConfiguredTests {
            static let model = ReferralAppModel(link: ReferralAppModelTests.link,
                                                component: ReferralAppModelTests.component,
                                                customParameters: ReferralAppModelTests.customParameters,
                                                bundle: InitLinkComponentCustomParametersTests.bundle)
            
            @Test("should return expected url scheme with all expected parameters")
            func testShouldReturnExpectedUrlScheme() {
                let urlScheme = RATIdentifiersConfiguredTests.model?.urlScheme(appScheme: "app")?.absoluteString
                #expect(urlScheme?.starts(with: "app://?ref=jp.co.rakuten.Host&ref_acc=477&ref_aid=1&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
                #expect(urlScheme?.contains("custom_param1=japan") == true)
                #expect(urlScheme?.contains("custom_param2=tokyo") == true)
                #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
                #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            }
            
            @Test("should return expected universal link with all expected parameters")
            func testShouldReturnExpectedUniversalLink() {
                let universalLink = RATIdentifiersConfiguredTests.model?.universalLink(domain: "rakuten.co.jp")?.absoluteString
                #expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=477&ref_aid=1&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
                #expect(universalLink?.contains("custom_param1=japan") == true)
                #expect(universalLink?.contains("custom_param2=tokyo") == true)
                #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
                #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            }
        }
        
        @Suite("When RAT identifiers are not configured")
        struct RATIdentifiersNotConfiguredTests {
            static let model = ReferralAppModel(link: ReferralAppModelTests.link,
                                                component: ReferralAppModelTests.component,
                                                customParameters: ReferralAppModelTests.customParameters,
                                                bundle: Bundle.main)
            
            @Test("should return expected url scheme with RAT identifiers and all expected parameters")
            func testShouldReturnExpectedUrlScheme() {
                let urlScheme = RATIdentifiersNotConfiguredTests.model?.urlScheme(appScheme: "app")?.absoluteString
                #expect(urlScheme?.starts(with: "app://?ref=jp.co.rakuten.Host&ref_acc=0&ref_aid=1&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
                #expect(urlScheme?.contains("custom_param1=japan") == true)
                #expect(urlScheme?.contains("custom_param2=tokyo") == true)
                #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
                #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            }
            
            @Test("should return expected universal link with RAT identifiers and all expected parameters")
            func testShouldReturnExpectedUniversalLink() {
                let universalLink = RATIdentifiersNotConfiguredTests.model?.universalLink(domain: "rakuten.co.jp")?.absoluteString
                #expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=0&ref_aid=1&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
                
                #expect(universalLink?.contains("custom_param1=japan") == true)
                #expect(universalLink?.contains("custom_param2=tokyo") == true)
                #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
                #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            }
        }
    }
    
    @Suite("init(accountIdentifier:applicationIdentifier:link:component:customParameters:)")
    struct InitAccountIdentifierTests {
        @Test("should return nil when bundleIdentifier is nil")
        func testShouldReturnNilWhenBundleIdentifierIsNil() {
            let bundle = BundleMock()
            bundle.bundleIdentifier = nil
            let model = ReferralAppModel(accountIdentifier: ReferralAppModelTests.accountIdentifier,
                                         applicationIdentifier: ReferralAppModelTests.applicationIdentifier,
                                         bundle: bundle)
            #expect(model == nil)
        }
        
        @Test("should return expected url scheme and expected universal link with minimal non-optional parameters")
        func testShouldReturnExpectedUrlSchemeAndUniversalLink() {
            let model = ReferralAppModel(accountIdentifier: ReferralAppModelTests.accountIdentifier,
                                         applicationIdentifier: ReferralAppModelTests.applicationIdentifier)
            #expect(model?.urlScheme(appScheme: "app")?.absoluteString == "app://?ref=jp.co.rakuten.Host&ref_acc=1&ref_aid=2")
            #expect(model?.universalLink(domain: "rakuten.co.jp")?.absoluteString == "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=1&ref_aid=2")
        }
        
        @Test("should return expected url scheme and expected universal link with all parameters")
        func testShouldReturnExpectedUrlSchemeAndUniversalLinkWithAllParameters() {
            let model = ReferralAppModel(accountIdentifier: ReferralAppModelTests.accountIdentifier,
                                         applicationIdentifier: ReferralAppModelTests.applicationIdentifier,
                                         link: ReferralAppModelTests.link,
                                         component: ReferralAppModelTests.component,
                                         customParameters: ReferralAppModelTests.customParameters,
                                         bundle: Bundle.main)
            let urlScheme = model?.urlScheme(appScheme: "app")?.absoluteString
            #expect(urlScheme?.starts(with: "app://?ref=jp.co.rakuten.Host&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(urlScheme?.contains("custom_param1=japan") == true)
            #expect(urlScheme?.contains("custom_param2=tokyo") == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            
            let universalLink = model?.universalLink(domain: "rakuten.co.jp")?.absoluteString
            #expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(universalLink?.contains("custom_param1=japan") == true)
            #expect(universalLink?.contains("custom_param2=tokyo") == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamRome) == true)
        }
    }
    
    @Suite("urlScheme(appScheme:, pathComponent:)")
    struct UrlSchemeTests {
        @Test("should return nil if the app scheme is empty")
        func testShouldReturnNilIfAppSchemeIsEmpty() {
            let urlScheme = ReferralAppModelTests.model.urlScheme(appScheme: "")?.absoluteString
            #expect(urlScheme == nil)
        }
        
        @Test("should return the expected URL without path component")
        func testShouldReturnExpectedURLWithoutPathComponent() {
            let urlScheme = ReferralAppModelTests.model.urlScheme(appScheme: "app")?.absoluteString
            #expect(urlScheme?.starts(with: "app://?ref=jp.co.rakuten.Host&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(urlScheme?.contains("custom_param1=japan") == true)
            #expect(urlScheme?.contains("custom_param2=tokyo") == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamRome) == true)
        }
        
        @Test("should return the expected URL with path component equal nil")
        func testShouldReturnExpectedURLWithPathComponentNil() {
            let urlScheme = ReferralAppModelTests.model.urlScheme(appScheme: "app", pathComponent: nil)?.absoluteString
            #expect(urlScheme?.starts(with: "app://?ref=jp.co.rakuten.Host&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            #expect(urlScheme?.contains("custom_param1=japan") == true)
            #expect(urlScheme?.contains("custom_param2=tokyo") == true)
        }
        
        @Test("should return the expected URL with path component")
        func testShouldReturnExpectedURLWithPathComponent() {
            let urlScheme = ReferralAppModelTests.model.urlScheme(appScheme: "app", pathComponent: "path/to/resource")?.absoluteString
            #expect(urlScheme?.starts(with: "app:///path/to/resource?ref=jp.co.rakuten.Host&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(urlScheme?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            #expect(urlScheme?.contains("custom_param1=japan") == true)
            #expect(urlScheme?.contains("custom_param2=tokyo") == true)
        }
    }
    
    @Suite("universalLink(domain:, pathComponent:)")
    struct UniversalLinkTests {
        @Test("should return nil if the domain is empty")
        func testShouldReturnNilIfDomainIsEmpty() {
            let universalLink = ReferralAppModelTests.model.universalLink(domain: "")?.absoluteString
            #expect(universalLink == nil)
        }
        
        @Test("should return the expected URL")
        func testShouldReturnExpectedURL() {
            let universalLink = ReferralAppModelTests.model.universalLink(domain: "rakuten.co.jp")?.absoluteString
            #expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            #expect(universalLink?.contains("custom_param1=japan") == true)
            #expect(universalLink?.contains("custom_param2=tokyo") == true)
        }
        
        @Test("should return the expected URL with path component equal nil")
        func testShouldReturnExpectedURLWithPathComponentNil() {
            let universalLink = ReferralAppModelTests.model.universalLink(domain: "rakuten.co.jp", pathComponent: nil)?.absoluteString
            #expect(universalLink?.starts(with: "https://rakuten.co.jp?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            #expect(universalLink?.contains("custom_param1=japan") == true)
            #expect(universalLink?.contains("custom_param2=tokyo") == true)
        }
        
        @Test("should return the expected URL with path component")
        func testShouldReturnExpectedURLWithPathComponent() {
            let universalLink = ReferralAppModelTests.model.universalLink(domain: "rakuten.co.jp", pathComponent: "path/to/resource")?.absoluteString
            #expect(universalLink?.starts(with: "https://rakuten.co.jp/path/to/resource?ref=\(ReferralAppModelTests.bundleIdentifier)&ref_acc=1&ref_aid=2&ref_link=campaignCode%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D&ref_comp=news%253A%2523%255B%255D%2540%2521%2524%2526%2527%2528%2529%252A%252B%252C%253B%253D") == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamItaly) == true)
            #expect(universalLink?.contains(ReferralAppModelTests.refCustomParamRome) == true)
            #expect(universalLink?.contains("custom_param1=japan") == true)
            #expect(universalLink?.contains("custom_param2=tokyo") == true)
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
