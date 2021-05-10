import Quick
import Nimble
@testable import RAnalytics

final class RATEncryptSpec: QuickSpec {
    override func spec() {
        describe("ratEncrypt") {
            it("should encrypt a string with alphanumeric and space characters") {
                let testString = "Hello World"
                let encryptedTestString = testString.ratEncrypt
                let correctEncryptionString = "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"
                expect(encryptedTestString).to(equal(correctEncryptionString))
            }
            it("should encrypt a string with special characters") {
                let testString = "%\n!@#$%^^&*()_+`?><][{}|\n,./;'+-"
                let encryptedTestString = testString.ratEncrypt
                let correctEncryptionString = "8acec974d460f10fef6f0bf3ca83072272fb42bff12e8038bb49609580090df8"
                expect(encryptedTestString).to(equal(correctEncryptionString))
            }
            it("should encrypt a string with numbers") {
                let testString = "1234567890"
                let encryptedTestString = testString.ratEncrypt
                let correctEncryptionString = "c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646"
                expect(encryptedTestString).to(equal(correctEncryptionString))
            }
            it("should encrypt an empty string") {
                let testString = ""
                let encryptedTestString = testString.ratEncrypt
                let correctEncryptionString = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                expect(encryptedTestString).to(equal(correctEncryptionString))
            }
            it("should encrypt a really long string") {
                var testString = "Hello World"
                (0..<5).forEach { _ in
                    testString += testString
                }
                let encryptedTestString = testString.ratEncrypt
                let correctEncryptionString = "894842ce15ce7c19419b3b59e86db242518896d9f735d2d74a97f0664bd25007"
                expect(encryptedTestString).to(equal(correctEncryptionString))
            }
        }
    }
}
