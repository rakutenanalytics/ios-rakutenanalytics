import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("KeychainHandler")
struct KeychainHandlerTests {
    static let key = "mykey"

    @Suite("string(for:)")
    struct StringForTests {
        @Suite("When the bundle identifier is not nil")
        struct WhenBundleIdentifierIsNotNilTests {
            var bundleMock: BundleMock
            var keychainHandler: KeychainHandler

            init() {
                bundleMock = BundleMock()
                bundleMock.bundleIdentifier = "identifier"
                keychainHandler = KeychainHandler(bundle: bundleMock)
            }

            mutating func tearDown() {
                try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
            }

            @Suite("When a non-nil value is stored")
            struct WhenNonNilValueStoredTests {
                var bundleMock: BundleMock
                var keychainHandler: KeychainHandler

                init() {
                    bundleMock = BundleMock()
                    bundleMock.bundleIdentifier = "identifier"
                    keychainHandler = KeychainHandler(bundle: bundleMock)
                }

                mutating func tearDown() {
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                }

                #if SWIFT_PACKAGE
                // The Keychain storage does not work in a Swift Package Tests target
                @Test("should not return the stored value")
                mutating func testDoesNotReturnStoredValue() {
                    defer { tearDown() }
                    try? keychainHandler.set(value: "helloworld", for: KeychainHandlerTests.key)
                    let result = try? keychainHandler.string(for: KeychainHandlerTests.key)

                    #expect(result == nil)
                }
                #else
                @Test("should return the stored value")
                mutating func testReturnsStoredValue() {
                    defer { tearDown() }
                    try? keychainHandler.set(value: "helloworld", for: KeychainHandlerTests.key)
                    let result = try? keychainHandler.string(for: KeychainHandlerTests.key)

                    #expect(result == "helloworld")
                }
                #endif
            }

            @Suite("When a nil value is stored")
            struct WhenNilValueStoredTests {
                var bundleMock: BundleMock
                var keychainHandler: KeychainHandler

                init() {
                    bundleMock = BundleMock()
                    bundleMock.bundleIdentifier = "identifier"
                    keychainHandler = KeychainHandler(bundle: bundleMock)
                }

                mutating func tearDown() {
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                }

                @Test("should return nil")
                mutating func testReturnsNil() {
                    defer { tearDown() }
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                    let result = try? keychainHandler.string(for: KeychainHandlerTests.key)

                    #expect(result == nil)
                }
            }

            @Suite("When there is no stored value")
            struct WhenNoStoredValueTests {
                var bundleMock: BundleMock
                var keychainHandler: KeychainHandler

                init() {
                    bundleMock = BundleMock()
                    bundleMock.bundleIdentifier = "identifier"
                    keychainHandler = KeychainHandler(bundle: bundleMock)
                }

                mutating func tearDown() {
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                }

                @Test("should return nil")
                mutating func testReturnsNil() {
                    defer { tearDown() }
                    let result = try? keychainHandler.string(for: KeychainHandlerTests.key)

                    #expect(result == nil)
                }
            }

            @Test("should not throw an error")
            mutating func testDoesNotThrowError() {
                defer { tearDown() }
                var didThrow = false
                do {
                    _ = try keychainHandler.string(for: KeychainHandlerTests.key)
                } catch {
                    didThrow = true
                }
                #expect(didThrow == false)
            }
        }

        @Suite("When the bundle identifier is nil")
        struct WhenBundleIdentifierIsNilTests {
            var bundleMock: BundleMock
            var keychainHandler: KeychainHandler

            init() {
                bundleMock = BundleMock()
                bundleMock.bundleIdentifier = nil
                keychainHandler = KeychainHandler(bundle: bundleMock)
            }

            mutating func tearDown() {
                try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
            }

            @Suite("When a non-nil value is stored")
            struct WhenNonNilValueStoredTests {
                var bundleMock: BundleMock
                var keychainHandler: KeychainHandler

                init() {
                    bundleMock = BundleMock()
                    bundleMock.bundleIdentifier = nil
                    keychainHandler = KeychainHandler(bundle: bundleMock)
                }

                mutating func tearDown() {
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                }

                @Test("should return nil")
                mutating func testReturnsNil() {
                    defer { tearDown() }
                    try? keychainHandler.set(value: "helloworld", for: KeychainHandlerTests.key)
                    let result = try? keychainHandler.string(for: KeychainHandlerTests.key)

                    #expect(result == nil)
                }
            }

            @Suite("When a nil value is stored")
            struct WhenNilValueStoredTests {
                var bundleMock: BundleMock
                var keychainHandler: KeychainHandler

                init() {
                    bundleMock = BundleMock()
                    bundleMock.bundleIdentifier = nil
                    keychainHandler = KeychainHandler(bundle: bundleMock)
                }

                mutating func tearDown() {
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                }

                @Test("should return nil")
                mutating func testReturnsNil() {
                    defer { tearDown() }
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                    let result = try? keychainHandler.string(for: KeychainHandlerTests.key)

                    #expect(result == nil)
                }
            }

            @Suite("When there is no stored value")
            struct WhenNoStoredValueTests {
                var bundleMock: BundleMock
                var keychainHandler: KeychainHandler

                init() {
                    bundleMock = BundleMock()
                    bundleMock.bundleIdentifier = nil
                    keychainHandler = KeychainHandler(bundle: bundleMock)
                }

                mutating func tearDown() {
                    try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
                }

                @Test("should return nil")
                mutating func testReturnsNil() {
                    defer { tearDown() }
                    let result = try? keychainHandler.string(for: KeychainHandlerTests.key)

                    #expect(result == nil)
                }
            }

            @Test("should throw an error")
            mutating func testThrowsError() {
                defer { tearDown() }
                var didThrow = false
                do {
                    _ = try keychainHandler.string(for: KeychainHandlerTests.key)
                } catch {
                    didThrow = true
                }
                #expect(didThrow == true)
            }
        }
    }

    @Suite("set(value:for:)")
    struct SetValueForTests {
        @Suite("When the bundle identifier is not nil")
        struct WhenBundleIdentifierIsNotNilTests {
            var bundleMock: BundleMock
            var keychainHandler: KeychainHandler

            init() {
                bundleMock = BundleMock()
                bundleMock.bundleIdentifier = "identifier"
                keychainHandler = KeychainHandler(bundle: bundleMock)
            }

            mutating func tearDown() {
                try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
            }

            #if SWIFT_PACKAGE
            // The Keychain storage does not work in a Swift Package Tests target
            @Test("should throw an error")
            mutating func testThrowsError() {
                defer { tearDown() }
                var didThrow = false
                do {
                    try keychainHandler.set(value: "helloworld", for: KeychainHandlerTests.key)
                } catch {
                    didThrow = true
                }
                #expect(didThrow == true)
            }
            #else
            @Test("should not throw an error")
            mutating func testDoesNotThrowError() {
                defer { tearDown() }
                var didThrow = false
                do {
                    try keychainHandler.set(value: "helloworld", for: KeychainHandlerTests.key)
                } catch {
                    didThrow = true
                }
                #expect(didThrow == false)
            }
            #endif
        }

        @Suite("When the bundle identifier is nil")
        struct WhenBundleIdentifierIsNilTests {
            var bundleMock: BundleMock
            var keychainHandler: KeychainHandler

            init() {
                bundleMock = BundleMock()
                bundleMock.bundleIdentifier = nil
                keychainHandler = KeychainHandler(bundle: bundleMock)
            }

            mutating func tearDown() {
                try? keychainHandler.set(value: nil, for: KeychainHandlerTests.key)
            }

            @Test("should throw an error")
            mutating func testThrowsError() {
                defer { tearDown() }
                var didThrow = false
                do {
                    try keychainHandler.set(value: "helloworld", for: KeychainHandlerTests.key)
                } catch {
                    didThrow = true
                }
                #expect(didThrow == true)
            }
        }
    }
}
