import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

class NSDateExtensionsSpec: QuickSpec {
    override class func spec() {
        describe("NSDate extension") {
            context("daysPassedSinceDate function") {
                it("should return 0 when the date is today") {
                    let today = Date()
                    let daysPassed = NSDate.daysPassedSinceDate(today)
                    
                    expect(daysPassed).to(equal(0))
                }
                
                it("should return the correct number of days for a past date") {
                    let calendar = Calendar.current
                    let pastDate = calendar.date(byAdding: .day, value: -10, to: Date())
                    let daysPassed = NSDate.daysPassedSinceDate(pastDate)
                    
                    expect(daysPassed).to(equal(10))
                }
                
                it("should return 0 when the date is nil") {
                    let daysPassed = NSDate.daysPassedSinceDate(nil)
                    
                    expect(daysPassed).to(equal(0))
                }
            }
        }
    }
}
