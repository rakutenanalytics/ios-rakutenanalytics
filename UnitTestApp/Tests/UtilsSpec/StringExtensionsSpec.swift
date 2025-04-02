import Foundation
import Quick
import Nimble
@testable import RakutenAnalytics

class StringExtensionsSpec: QuickSpec {

    override class func spec() {

        describe("StringExtensions") {

            describe("addEncodingForRFC3986UnreservedCharacters") {

                context("The string to encode is empty") {

                    it("should return empty string") {
                        let str = ""
                        expect(str.addEncodingForRFC3986UnreservedCharacters()).to(equal(""))
                    }
                }

                context("The string to encode is not empty") {

                    it("should return the same string when it does not contain RFC3986 reserved characters") {
                        let str = "sentence"
                        expect(str.addEncodingForRFC3986UnreservedCharacters()).to(equal("sentence"))
                    }

                    it("should return the encoded string when it contains RFC3986 reserved characters") {
                        let str = "sentence:#[]@!$&'()*+,;="
                        expect(str.addEncodingForRFC3986UnreservedCharacters()).to(equal("sentence%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D"))
                    }
                }
            }

            describe("Subscript") {
                context("Range in bounds") {
                    it("should return a substring") {
                        expect("hello"[2..<4]).to(equal("ll"))
                    }
                }
            }
        }
    }
}
