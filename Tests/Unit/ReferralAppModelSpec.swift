// swiftlint:disable line_length

import Quick
import Nimble
@testable import RAnalytics

// MARK: - ReferralAppModelSpec

final class ReferralAppModelSpec: QuickSpec {
    override func spec() {
        describe("ReferralAppModel") {
            describe("init") {
                context("Initialization with mandatory parameters") {
                    it("should be initialized with expected values") {
                        let model = ReferralAppModel(bundleIdentifier: "jp.co.rakuten.app",
                                                     accountIdentifier: 1,
                                                     applicationIdentifier: 2,
                                                     link: nil,
                                                     component: nil,
                                                     customParameters: [:])

                        expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                        expect(model.accountIdentifier).to(equal(1))
                        expect(model.applicationIdentifier).to(equal(2))
                        expect(model.link).to(beNil())
                        expect(model.component).to(beNil())
                        expect(model.customParameters).to(equal([:]))
                    }
                }

                context("Initialization with mandatory and optional parameters") {
                    it("should be initialized with expected values") {
                        let model = ReferralAppModel(bundleIdentifier: "jp.co.rakuten.app",
                                                     accountIdentifier: 1,
                                                     applicationIdentifier: 2,
                                                     link: "campaignCode",
                                                     component: "news",
                                                     customParameters: ["key1": "value1"])

                        expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                        expect(model.accountIdentifier).to(equal(1))
                        expect(model.applicationIdentifier).to(equal(2))
                        expect(model.link).to(equal("campaignCode"))
                        expect(model.component).to(equal("news"))
                        expect(model.customParameters).to(equal(["key1": "value1"]))
                    }
                }
            }

            describe("init(url:sourceApplication:)") {
                let bundleIdentifier = "jp.co.rakuten.app"
                let bundleIdentifierQueryItem = "\(PayloadParameterKeys.ref)=\(bundleIdentifier)"
                let accountIdentifierQueryItem = "\(PayloadParameterKeys.refAccountIdentifier)=1"
                let applicationIdentifierQueryItem = "\(PayloadParameterKeys.refApplicationIdentifier)=2"
                let linkQueryItem = "\(PayloadParameterKeys.refLink)=campaignCode"
                let componentQueryItem = "\(PayloadParameterKeys.refComponent)=news"
                let mandatoryParametersQueryItems = "\(accountIdentifierQueryItem)&\(applicationIdentifierQueryItem)"

                it("should fail when mandatory parameters are missing") {
                    // URL Scheme
                    expect(ReferralAppModel(url: URL(string: "app://")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "app://?\(accountIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "app://?\(applicationIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())

                    // Universal Link
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(accountIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(applicationIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(accountIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())
                    expect(ReferralAppModel(url: URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(applicationIdentifierQueryItem)")!, sourceApplication: bundleIdentifier)).to(beNil())
                }

                context("Initialization with mandatory parameters") {
                    it("should be initialized with expected values") {
                        let appURL = URL(string: "app://?\(mandatoryParametersQueryItems)")!
                        let appModel = ReferralAppModel(url: appURL, sourceApplication: bundleIdentifier)!
                        verify(model: appModel)

                        let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(mandatoryParametersQueryItems)")!
                        let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                        verify(model: universalModel)
                    }

                    func verify(model: ReferralAppModel) {
                        expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                        expect(model.accountIdentifier).to(equal(1))
                        expect(model.applicationIdentifier).to(equal(2))
                        expect(model.link).to(beNil())
                        expect(model.component).to(beNil())
                        expect(model.customParameters).to(equal([:]))
                    }
                }

                context("Initialization with mandatory and optional parameters") {
                    var customParameters = [String: String]()

                    afterEach {
                        customParameters.removeAll()
                    }

                    context("Only a link is provided") {
                        it("should be initialized with expected values") {
                            let commonParameters = "\(mandatoryParametersQueryItems)&\(linkQueryItem)"
                            let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: bundleIdentifier)!
                            verify(model: appModel)

                            let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                            let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                            verify(model: universalModel)
                        }

                        func verify(model: ReferralAppModel) {
                            expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal("campaignCode"))
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
                            let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                            verify(model: universalModel)
                        }

                        func verify(model: ReferralAppModel) {
                            expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(beNil())
                            expect(model.component).to(equal("news"))
                            expect(model.customParameters).to(equal([:]))
                        }
                    }

                    context("Only custom parameters are provided") {
                        it("should be initialized with expected values") {
                            (0...5).forEach { index in
                                customParameters["key\(index)"] = "value\(index)"

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(customParameters.toQuery)"

                                let url = URL(string: "app://?\(commonParameters)")!
                                let appModel = ReferralAppModel(url: url, sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)

                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
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
                            let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                            verify(model: universalModel)
                        }

                        func verify(model: ReferralAppModel) {
                            expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal("campaignCode"))
                            expect(model.component).to(equal("news"))
                            expect(model.customParameters).to(equal([:]))
                        }
                    }

                    context("Only a link and custom parameters are provided") {
                        it("should be initialized with expected values") {
                            (0...5).forEach { index in
                                customParameters["key\(index)"] = "value\(index)"

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(linkQueryItem)&\(customParameters.toQuery)"

                                let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!, sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)

                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal("campaignCode"))
                            expect(model.component).to(beNil())
                            expect(model.customParameters).to(equal(customParameters))
                        }
                    }

                    context("Only a component and custom parameters are provided") {
                        it("should be initialized with expected values") {
                            (0...5).forEach { index in
                                customParameters["key\(index)"] = "value\(index)"

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(componentQueryItem)&\(customParameters.toQuery)"

                                let appModel = ReferralAppModel(url: URL(string: "app://?\(commonParameters)")!,
                                                                sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)

                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(beNil())
                            expect(model.component).to(equal("news"))
                            expect(model.customParameters).to(equal(customParameters))
                        }
                    }

                    context("Link, component and custom parameters are provided") {
                        it("should be initialized with expected values") {
                            (0...5).forEach { index in
                                customParameters["key\(index)"] = "value\(index)"

                                let commonParameters = "\(mandatoryParametersQueryItems)&\(linkQueryItem)&\(componentQueryItem)&\(customParameters.toQuery)"

                                let appURL = URL(string: "app://?\(commonParameters)")!
                                let appModel = ReferralAppModel(url: appURL, sourceApplication: bundleIdentifier)!
                                verify(model: appModel, customParameters: customParameters)

                                let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(bundleIdentifierQueryItem)&\(commonParameters)")!
                                let universalModel = ReferralAppModel(url: universalLinkURL, sourceApplication: bundleIdentifier)!
                                verify(model: universalModel, customParameters: customParameters)
                            }
                        }

                        func verify(model: ReferralAppModel, customParameters: [String: String]) {
                            expect(model.bundleIdentifier).to(equal("jp.co.rakuten.app"))
                            expect(model.accountIdentifier).to(equal(1))
                            expect(model.applicationIdentifier).to(equal(2))
                            expect(model.link).to(equal("campaignCode"))
                            expect(model.component).to(equal("news"))
                            expect(model.customParameters).to(equal(customParameters))
                        }
                    }
                }
            }
        }
    }
}
