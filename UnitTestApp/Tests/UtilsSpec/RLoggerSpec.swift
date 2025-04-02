import Quick
import Nimble
@testable import RakutenAnalytics

class RLoggerSpec: QuickSpec {
    override class func spec() {

        describe("RLogger") {

            beforeSuite {
                // context("loggingLevel")
                // it("should return RLoggingLevel.error by default")
                expect(RLogger.loggingLevel).to(equal(.error))
            }

            describe("callerModuleName") {
                it("should return RakutenAnalytics or UtilsSpec (spm)") {
                    expect(["RakutenAnalytics", "UtilsSpec", "UnitTests"]).to(contain(RLogger.callerModuleName))
                }
            }

            describe("log(_:message:)") {
                context("when a message is logged") {
                    it("should return message from this level: RLoggingLevel.verbose") {
                        RLogger.loggingLevel = .verbose
                        expect(RLogger.verbose(message: "test")).to(equal("test"))
                        expect(RLogger.debug(message: "test")).to(equal("test"))
                        expect(RLogger.info(message: "test")).to(equal("test"))
                        expect(RLogger.warning(message: "test")).to(equal("test"))
                        expect(RLogger.error(message: "test")).to(equal("test"))
                    }

                    it("should return message from this level: RLoggingLevel.debug") {
                        RLogger.loggingLevel = .debug
                        expect(RLogger.verbose(message: "test")).to(beNil())
                        expect(RLogger.debug(message: "test")).to(equal("test"))
                        expect(RLogger.info(message: "test")).to(equal("test"))
                        expect(RLogger.warning(message: "test")).to(equal("test"))
                        expect(RLogger.error(message: "test")).to(equal("test"))
                    }

                    it("should return message from this level: RLoggingLevel.info") {
                        RLogger.loggingLevel = .info
                        expect(RLogger.verbose(message: "test")).to(beNil())
                        expect(RLogger.debug(message: "test")).to(beNil())
                        expect(RLogger.info(message: "test")).to(equal("test"))
                        expect(RLogger.warning(message: "test")).to(equal("test"))
                        expect(RLogger.error(message: "test")).to(equal("test"))
                    }

                    it("should return message from this level: RLoggingLevel.warning") {
                        RLogger.loggingLevel = .warning
                        expect(RLogger.verbose(message: "test")).to(beNil())
                        expect(RLogger.debug(message: "test")).to(beNil())
                        expect(RLogger.info(message: "test")).to(beNil())
                        expect(RLogger.warning(message: "test")).to(equal("test"))
                        expect(RLogger.error(message: "test")).to(equal("test"))
                    }

                    it("should return message from this level: RLoggingLevel.error") {
                        RLogger.loggingLevel = .error
                        expect(RLogger.verbose(message: "test")).to(beNil())
                        expect(RLogger.debug(message: "test")).to(beNil())
                        expect(RLogger.info(message: "test")).to(beNil())
                        expect(RLogger.warning(message: "test")).to(beNil())
                        expect(RLogger.error(message: "test")).to(equal("test"))
                    }

                    it("should return message from this level: RLoggingLevel.none") {
                        RLogger.loggingLevel = .none
                        expect(RLogger.verbose(message: "test")).to(beNil())
                        expect(RLogger.debug(message: "test")).to(beNil())
                        expect(RLogger.info(message: "test")).to(beNil())
                        expect(RLogger.warning(message: "test")).to(beNil())
                        expect(RLogger.error(message: "test")).to(beNil())
                    }
                }
            }
        }
    }
}
