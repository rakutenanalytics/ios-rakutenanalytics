import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - PositiveIntegerNumberTests

@Suite("PositiveIntegerNumber")
struct PositiveIntegerNumberTests {
    @Test("should return nil when called from an optional")
    func testReturnsNilWhenCalledFromOptional() {
        let object: NSObject? = nil
        #expect(object?.positiveIntegerNumber == nil)
    }

    @Test("should return nil when the value is 0")
    func testReturnsNilWhenValueIsZero() {
        let num = 0
        #expect(NSNumber(value: num).positiveIntegerNumber == nil)
    }

    @Test("should return nil when the value type is Double")
    func testReturnsNilWhenValueTypeIsDouble() {
        let num: Double = 123.4
        #expect(NSNumber(value: num).positiveIntegerNumber == nil)
    }

    @Test("should return nil when the value type is Float")
    func testReturnsNilWhenValueTypeIsFloat() {
        let num: Float = 123.4
        #expect(NSNumber(value: num).positiveIntegerNumber == nil)
    }

    @Suite("When the value is > 0")
    struct WhenValueIsGreaterThanZeroTests {
        @Test("should return the expected Int value")
        func testReturnsExpectedIntValue() {
            let num: Int = 123
            #expect(NSNumber(value: num).positiveIntegerNumber == NSNumber(value: num))
        }

        @Test("should return the expected Int8 value")
        func testReturnsExpectedInt8Value() {
            let num: Int8 = 123
            #expect(NSNumber(value: num).positiveIntegerNumber == NSNumber(value: num))
        }

        @Test("should return the expected Int16 value")
        func testReturnsExpectedInt16Value() {
            let num: Int16 = 123
            #expect(NSNumber(value: num).positiveIntegerNumber == NSNumber(value: num))
        }

        @Test("should return the expected Int32 value")
        func testReturnsExpectedInt32Value() {
            let num: Int32 = 123
            #expect(NSNumber(value: num).positiveIntegerNumber == NSNumber(value: num))
        }

        @Test("should return the expected Int64 value")
        func testReturnsExpectedInt64Value() {
            let num: Int64 = 123
            #expect(NSNumber(value: num).positiveIntegerNumber == NSNumber(value: num))
        }
    }

    @Suite("When the value is < 0")
    struct WhenValueIsLessThanZeroTests {
        @Test("should return nil for Int")
        func testReturnsNilForInt() {
            let num: Int = -123
            #expect(NSNumber(value: num).positiveIntegerNumber == nil)
        }

        @Test("should return nil for Int8")
        func testReturnsNilForInt8() {
            let num: Int8 = -123
            #expect(NSNumber(value: num).positiveIntegerNumber == nil)
        }

        @Test("should return nil for Int16")
        func testReturnsNilForInt16() {
            let num: Int16 = -123
            #expect(NSNumber(value: num).positiveIntegerNumber == nil)
        }

        @Test("should return nil for Int32")
        func testReturnsNilForInt32() {
            let num: Int32 = -123
            #expect(NSNumber(value: num).positiveIntegerNumber == nil)
        }

        @Test("should return nil for Int64")
        func testReturnsNilForInt64() {
            let num: Int64 = -123
            #expect(NSNumber(value: num).positiveIntegerNumber == nil)
        }
    }

    @Suite("When the value is String")
    struct WhenValueIsStringTests {
        @Test("should return nil when the string value contains 0")
        func testReturnsNilWhenStringContainsZero() {
            #expect("0".positiveIntegerNumber == nil)
        }

        @Test("should return the expected value when the string value contains a positive number")
        func testReturnsExpectedValueWhenStringContainsPositiveNumber() {
            #expect("123".positiveIntegerNumber == NSNumber(value: 123))
        }

        @Test("should return nil when the string value contains a negative number")
        func testReturnsNilWhenStringContainsNegativeNumber() {
            #expect("-123".positiveIntegerNumber == nil)
        }

        @Test("should return nil when the string value contains a float number")
        func testReturnsNilWhenStringContainsFloatNumber() {
            #expect("12.3".positiveIntegerNumber == nil)
        }

        @Test("should return the expected value when the string value contains a positive number prefixed by 0")
        func testReturnsExpectedValueWhenStringContainsPositiveNumberPrefixedByZero() {
            #expect("01".positiveIntegerNumber == 1)
        }

        @Test("should return nil when the string value contains a space character")
        func testReturnsNilWhenStringContainsSpaceCharacter() {
            #expect("12 3".positiveIntegerNumber == nil)
        }

        @Test("should return nil when the string value contains a character")
        func testReturnsNilWhenStringContainsCharacter() {
            #expect("12e3".positiveIntegerNumber == nil)
        }
    }
}
