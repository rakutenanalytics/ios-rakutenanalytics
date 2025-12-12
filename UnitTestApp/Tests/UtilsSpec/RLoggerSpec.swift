import Testing
@testable import RakutenAnalytics

@Suite("RLogger")
struct RLoggerSpec {
    
    @Test("should return RLoggingLevel.error by default")
    func testDefaultLoggingLevel() {
        // Verify default logging level is .error
        #expect(RLogger.loggingLevel == .error)
    }
    
    @Suite("callerModuleName")
    struct CallerModuleNameTests {
        @Test("should return RakutenAnalytics or UtilsSpec (spm)")
        func testCallerModuleName() {
            #expect(["RakutenAnalytics", "UtilsSpec", "UnitTests"].contains(RLogger.callerModuleName))
        }
    }
    
    @Suite("log(_:message:)")
    struct LogMessageTests {
        @Suite("when a message is logged")
        struct WhenMessageIsLoggedTests {
            @Test("should return message from this level: RLoggingLevel.verbose")
            func testVerboseLevel() {
                RLogger.loggingLevel = .verbose
                #expect(RLogger.verbose(message: "test") == "test")
                #expect(RLogger.debug(message: "test") == "test")
                #expect(RLogger.info(message: "test") == "test")
                #expect(RLogger.warning(message: "test") == "test")
                #expect(RLogger.error(message: "test") == "test")
            }
            
            @Test("should return message from this level: RLoggingLevel.debug")
            func testDebugLevel() {
                RLogger.loggingLevel = .debug
                #expect(RLogger.verbose(message: "test") == nil)
                #expect(RLogger.debug(message: "test") == "test")
                #expect(RLogger.info(message: "test") == "test")
                #expect(RLogger.warning(message: "test") == "test")
                #expect(RLogger.error(message: "test") == "test")
            }
            
            @Test("should return message from this level: RLoggingLevel.info")
            func testInfoLevel() {
                RLogger.loggingLevel = .info
                #expect(RLogger.verbose(message: "test") == nil)
                #expect(RLogger.debug(message: "test") == nil)
                #expect(RLogger.info(message: "test") == "test")
                #expect(RLogger.warning(message: "test") == "test")
                #expect(RLogger.error(message: "test") == "test")
            }
            
            @Test("should return message from this level: RLoggingLevel.warning")
            func testWarningLevel() {
                RLogger.loggingLevel = .warning
                #expect(RLogger.verbose(message: "test") == nil)
                #expect(RLogger.debug(message: "test") == nil)
                #expect(RLogger.info(message: "test") == nil)
                #expect(RLogger.warning(message: "test") == "test")
                #expect(RLogger.error(message: "test") == "test")
            }
            
            @Test("should return message from this level: RLoggingLevel.error")
            func testErrorLevel() {
                RLogger.loggingLevel = .error
                #expect(RLogger.verbose(message: "test") == nil)
                #expect(RLogger.debug(message: "test") == nil)
                #expect(RLogger.info(message: "test") == nil)
                #expect(RLogger.warning(message: "test") == nil)
                #expect(RLogger.error(message: "test") == "test")
            }
            
            @Test("should return message from this level: RLoggingLevel.none")
            func testNoneLevel() {
                RLogger.loggingLevel = .none
                #expect(RLogger.verbose(message: "test") == nil)
                #expect(RLogger.debug(message: "test") == nil)
                #expect(RLogger.info(message: "test") == nil)
                #expect(RLogger.warning(message: "test") == nil)
                #expect(RLogger.error(message: "test") == nil)
            }
        }
    }
}
