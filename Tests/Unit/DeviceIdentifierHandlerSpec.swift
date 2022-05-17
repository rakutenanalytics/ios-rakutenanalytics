import Quick
import Nimble
import Foundation
@testable import RAnalytics

final class DeviceIdentifierHandlerSpec: QuickSpec {
    override func spec() {
        describe("DeviceIdentifierHandler") {
            let deviceIdentifierMock = DeviceMock()

            describe("ckp()") {
                context("When idfvUUID is nil") {
                    it("should return a non-empty value") {
                        deviceIdentifierMock.idfvUUID = nil
                        let handler = DeviceIdentifierHandler(device: deviceIdentifierMock)

                        expect(handler.ckp()).toNot(beEmpty())
                    }
                }

                context("When idfvUUID is an empty String") {
                    it("should return a non-empty value") {
                        deviceIdentifierMock.idfvUUID = ""
                        let handler = DeviceIdentifierHandler(device: deviceIdentifierMock)

                        expect(handler.ckp()).toNot(beEmpty())
                    }
                }

                context("When idfvUUID equals 00000000-0000-0000-0000-000000000000") {
                    it("should return a non-empty value") {
                        deviceIdentifierMock.idfvUUID = "00000000-0000-0000-0000-000000000000"
                        let handler = DeviceIdentifierHandler(device: deviceIdentifierMock)

                        expect(handler.ckp()).toNot(beEmpty())
                    }
                }

                context("When idfvUUID equals 123e4567-e89b-12d3-a456-426652340000") {
                    it("should return 428529fb27609e73dce768588ba6f1a1c1647451") {
                        deviceIdentifierMock.idfvUUID = "123e4567-e89b-12d3-a456-426652340000"
                        let handler = DeviceIdentifierHandler(device: deviceIdentifierMock)

                        expect(handler.ckp()).to(equal("428529fb27609e73dce768588ba6f1a1c1647451"))
                    }
                }
            }
        }
    }
}
