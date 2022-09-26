import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class KeychainHandlerSpec: QuickSpec {
    override func spec() {
        describe("KeychainHandler") {
            let key = "mykey"
            let bundleMock = BundleMock()
            let keychainHandler = KeychainHandler(bundle: bundleMock)

            afterEach {
                // Delete the stored value after each test
                try? keychainHandler.set(value: nil, for: key)
            }

            describe("string(for:)") {
                context("When the bundle identifier is not nil") {
                    beforeEach {
                        bundleMock.bundleIdentifier = "identifier"
                    }

                    context("When a non-nil value is stored") {
                        #if SWIFT_PACKAGE
                        // The Keychain storage does not work in a Swift Package Tests target
                        it("should not return the stored value") {
                            try? keychainHandler.set(value: "helloworld", for: key)
                            let result = try? keychainHandler.string(for: key)

                            expect(result).to(beNil())
                        }
                        #else
                        it("should return the stored value") {
                            try? keychainHandler.set(value: "helloworld", for: key)
                            let result = try? keychainHandler.string(for: key)

                            expect(result).to(equal("helloworld"))
                        }
                        #endif
                    }

                    context("When a nil value is stored") {
                        it("should return nil") {
                            try? keychainHandler.set(value: nil, for: key)
                            let result = try? keychainHandler.string(for: key)

                            expect(result).to(beNil())
                        }
                    }

                    context("When there is no stored value") {
                        it("should return nil") {
                            let result = try? keychainHandler.string(for: key)

                            expect(result).to(beNil())
                        }
                    }

                    it("should not throw an error") {
                        expect(try keychainHandler.string(for: key)).toNot(throwError())
                    }
                }

                context("When the bundle identifier is nil") {
                    beforeEach {
                        bundleMock.bundleIdentifier = nil
                    }

                    context("When a non-nil value is stored") {
                        it("should return nil") {
                            try? keychainHandler.set(value: "helloworld", for: key)
                            let result = try? keychainHandler.string(for: key)

                            expect(result).to(beNil())
                        }
                    }

                    context("When a nil value is stored") {
                        it("should return nil") {
                            try? keychainHandler.set(value: nil, for: key)
                            let result = try? keychainHandler.string(for: key)

                            expect(result).to(beNil())
                        }
                    }

                    context("When there is no stored value") {
                        it("should return nil") {
                            let result = try? keychainHandler.string(for: key)

                            expect(result).to(beNil())
                        }
                    }

                    it("should throw an error") {
                        expect(try keychainHandler.string(for: key)).to(throwError())
                    }
                }
            }

            describe("set(value:for:)") {
                context("When the bundle identifier is not nil") {
                    beforeEach {
                        bundleMock.bundleIdentifier = "identifier"
                    }

                    #if SWIFT_PACKAGE
                    // The Keychain storage does not work in a Swift Package Tests target
                    it("should throw an error") {
                        expect(try keychainHandler.set(value: "helloworld", for: key)).to(throwError())
                    }
                    #else
                    it("should not throw an error") {
                        expect(try keychainHandler.set(value: "helloworld", for: key)).toNot(throwError())
                    }
                    #endif
                }

                context("When the bundle identifier is nil") {
                    beforeEach {
                        bundleMock.bundleIdentifier = nil
                    }

                    it("should throw an error") {
                        expect(try keychainHandler.set(value: "helloworld", for: key)).to(throwError())
                    }
                }
            }
        }
    }
}
