import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - PositiveIntegerNumberSpec

final class PositiveIntegerNumberSpec: QuickSpec {

    override class func spec() {
        describe("PositiveIntegerNumber") {
            it("should return nil when called from an optional") {
                let object: NSObject? = nil
                expect(object?.positiveIntegerNumber).to(beNil())
            }

            it("should return nil when the value is 0") {
                let num = 0
                expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
            }

            it("should return nil when the value type is Double") {
                let num: Double = 123.4
                expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
            }

            it("should return nil when the value type is Float") {
                let num: Float = 123.4
                expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
            }

            context("When the value is > 0") {
                it("should return the expected Int value") {
                    let num: Int = 123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(equal(NSNumber(value: num)))
                }

                it("should return the expected Int8 value") {
                    let num: Int8 = 123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(equal(NSNumber(value: num)))
                }

                it("should return the expected Int16 value") {
                    let num: Int16 = 123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(equal(NSNumber(value: num)))
                }

                it("should return the expected Int32 value") {
                    let num: Int32 = 123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(equal(NSNumber(value: num)))
                }

                it("should return the expected Int64 value") {
                    let num: Int64 = 123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(equal(NSNumber(value: num)))
                }
            }

            context("When the value is < 0") {
                it("should return nil") {
                    let num: Int = -123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
                }

                it("should return nil") {
                    let num: Int8 = -123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
                }

                it("should return nil") {
                    let num: Int16 = -123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
                }

                it("should return nil") {
                    let num: Int32 = -123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
                }

                it("should return nil") {
                    let num: Int64 = -123
                    expect(NSNumber(value: num).positiveIntegerNumber).to(beNil())
                }
            }

            context("When the value is String") {
                it("should return nil when the string value contains 0") {
                    expect("0".positiveIntegerNumber).to(beNil())
                }

                it("should return the expected value when the string value contains a positive number") {
                    expect("123".positiveIntegerNumber).to(equal(NSNumber(value: 123)))
                }

                it("should return nil when the string value contains a negative number") {
                    expect("-123".positiveIntegerNumber).to(beNil())
                }

                it("should return nil when the string value contains a float number") {
                    expect("12.3".positiveIntegerNumber).to(beNil())
                }

                it("should return the expected value when the string value contains a positive number prefixed by 0") {
                    expect("01".positiveIntegerNumber).to(equal(1))
                }

                it("should return nil when the string value contains a space character") {
                    expect("12 3".positiveIntegerNumber).to(beNil())
                }

                it("should return nil when the string value contains a character") {
                    expect("12e3".positiveIntegerNumber).to(beNil())
                }
            }
        }
    }
}
