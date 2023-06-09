import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

private struct NilHasher: SecureHashable {
    func sha1(value: String) -> Data? {
        nil
    }
}

final class DeviceIdentifierHandlerSpec: QuickSpec {
    override func spec() {
        describe("DeviceIdentifierHandler") {
            let deviceIdentifierMock = DeviceMock()

            describe("ckp()") {
                context("When idfvUUID is nil") {
                    context("When sha1() returns nil") {
                        it("should return NO_DEVICE_ID_FOUND") {
                            deviceIdentifierMock.idfvUUID = nil
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())

                            expect(handler.ckp()).to(equal("NO_DEVICE_ID_FOUND"))
                        }
                    }

                    context("When sha1() returns a non-nil value") {
                        it("should return a non-empty value") {
                            deviceIdentifierMock.idfvUUID = nil
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())

                            expect(handler.ckp()).toNot(beEmpty())
                        }
                    }
                }

                context("When idfvUUID is an empty String") {
                    context("When sha1() returns nil") {
                        it("should return NO_DEVICE_ID_FOUND") {
                            deviceIdentifierMock.idfvUUID = ""
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())

                            expect(handler.ckp()).to(equal("NO_DEVICE_ID_FOUND"))
                        }
                    }

                    context("When sha1() returns a non-nil value") {
                        it("should return a non-empty value") {
                            deviceIdentifierMock.idfvUUID = ""
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())

                            expect(handler.ckp()).toNot(beEmpty())
                        }
                    }
                }

                context("When idfvUUID equals 00000000-0000-0000-0000-000000000000") {
                    context("When sha1() returns nil") {
                        it("should return NO_DEVICE_ID_FOUND") {
                            deviceIdentifierMock.idfvUUID = "00000000-0000-0000-0000-000000000000"
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())

                            expect(handler.ckp()).to(equal("NO_DEVICE_ID_FOUND"))
                        }
                    }

                    context("When sha1() returns a non-nil value") {
                        it("should return a non-empty value") {
                            deviceIdentifierMock.idfvUUID = "00000000-0000-0000-0000-000000000000"
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())

                            expect(handler.ckp()).toNot(beEmpty())
                        }
                    }
                }

                context("When idfvUUID equals 123e4567-e89b-12d3-a456-426652340000") {
                    context("When sha1() returns nil") {
                        it("should return NO_DEVICE_ID_FOUND") {
                            deviceIdentifierMock.idfvUUID = "123e4567-e89b-12d3-a456-426652340000"
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())

                            expect(handler.ckp()).to(equal("NO_DEVICE_ID_FOUND"))
                        }
                    }

                    context("When sha1() returns a non-nil value") {
                        it("should return 428529fb27609e73dce768588ba6f1a1c1647451") {
                            deviceIdentifierMock.idfvUUID = "123e4567-e89b-12d3-a456-426652340000"
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())

                            expect(handler.ckp()).to(equal("428529fb27609e73dce768588ba6f1a1c1647451"))
                        }

                        it("should return 98f43051f367e16779c645e32fb731368e9fa792") {
                            deviceIdentifierMock.idfvUUID = "D552F5FB-270F-4236-8FE9-11C14A353E71"
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())

                            expect(handler.ckp()).to(equal("98f43051f367e16779c645e32fb731368e9fa792"))
                        }

                        it("should return ba63e16988f226917060c08f19e060f119509e9c") {
                            deviceIdentifierMock.idfvUUID = "8D0E6370-A418-4A3C-81E1-6211D9C74071"
                            let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())

                            expect(handler.ckp()).to(equal("ba63e16988f226917060c08f19e060f119509e9c"))
                        }
                    }
                }
            }
        }
    }
}
