import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("NSDate extension")
struct NSDateExtensionsSpec {
    @Suite("daysPassedSinceDate function")
    struct DaysPassedSinceDateTests {
        @Test("should return 0 when the date is today")
        func testReturnsZeroForToday() {
            let today = Date()
            let daysPassed = NSDate.daysPassedSinceDate(today)
            
            #expect(daysPassed == 0)
        }
        
        @Test("should return the correct number of days for a past date")
        func testReturnsCorrectDaysForPastDate() {
            let calendar = Calendar.current
            let pastDate = calendar.date(byAdding: .day, value: -10, to: Date())
            let daysPassed = NSDate.daysPassedSinceDate(pastDate)
            
            #expect(daysPassed == 10)
        }
        
        @Test("should return 0 when the date is nil")
        func testReturnsZeroForNilDate() {
            let daysPassed = NSDate.daysPassedSinceDate(nil)
            
            #expect(daysPassed == 0)
        }
    }
}
