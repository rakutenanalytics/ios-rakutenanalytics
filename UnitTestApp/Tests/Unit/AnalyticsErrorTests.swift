import Testing
import Foundation
@testable import RakutenAnalytics

@Suite("AnalyticsError")
struct AnalyticsErrorTests {
    @Suite("nsError()")
    struct NSErrorTests {
        @Test("should return the expected embedded error")
        func testReturnsExpectedEmbeddedError() {
            let error = AnalyticsError.embeddedError(ErrorConstants.statusCodeError(with: 400))
            
            let nsError = error.nsError()
            #expect(nsError.domain == NSURLErrorDomain)
            #expect(nsError.code == NSURLErrorUnknown)
            #expect(nsError.localizedDescription == ErrorDescription.statusCodeError)
            #expect(nsError.localizedFailureReason == ErrorReason.statusCodeError(400))
        }
        
        @Test("should return the expected detailed error")
        func testReturnsExpectedDetailedError() {
            let error = AnalyticsError.detailedError(domain: "domain", code: 123, description: "description", reason: "reason")
            
            let nsError = error.nsError()
            #expect(nsError.domain == "domain")
            #expect(nsError.code == 123)
            #expect(nsError.localizedDescription == "description")
            #expect(nsError.localizedFailureReason == "reason")
        }
    }
    
    @Suite("log()")
    struct LogTests {
        @Test("should log the expected embedded error")
        func testLogsExpectedEmbeddedError() {
            let error = AnalyticsError.embeddedError(ErrorConstants.statusCodeError(with: 400))
            #expect(error.log() == error.nsError().localizedDescription)
        }
        
        @Test("should log the expected detailed error")
        func testLogsExpectedDetailedError() {
            let error = AnalyticsError.detailedError(domain: "domain", code: 123, description: "description", reason: "reason")
            #expect(error.log() == "domain, 123, description, reason")
        }
    }
    
    @Suite("ErrorConstants")
    struct ErrorConstantsTests {
        @Test("should return the expected pushConversionError")
        func testReturnsExpectedPushConversionError() {
            let error = ErrorConstants.pushConversionError
            #expect(error.domain == ErrorDomain.pushConversionTrackingErrorDomain)
            #expect(error.code == ErrorCode.pushConversionTrackingFailure.rawValue)
            #expect(error.localizedDescription == ErrorDescription.pushConversionTrackingFailed)
            #expect(error.localizedFailureReason == ErrorReason.emptyParameters)
        }
    }
}
