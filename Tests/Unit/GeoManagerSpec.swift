import Quick
import Nimble
import CoreLocation
@testable import RAnalytics

final class GeoManagerSpec: QuickSpec {

    override func spec() {
        describe("GeoManager") {
            context("singleton plus") {
                it("should not be nil on accessing shared instance") {
                    expect(GeoManager.shared).toNot(beNil())
                }

                it("should not be nil on creating a new instance") {
                    let manager = GeoManager()
                    expect(manager).toNot(beNil())
                }
            }
        }
    }
}
