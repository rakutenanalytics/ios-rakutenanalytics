import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

private struct NilHasher: SecureHashable {
    func sha1(value: String) -> Data? {
        nil
    }
}

@Suite("DeviceIdentifierHandler")
struct DeviceIdentifierHandlerTests {
    @Suite("ckp()")
    struct CkpTests {
        @Suite("When idfvUUID is nil")
        struct WhenIdfvUUIDIsNilTests {
            @Suite("When sha1() returns nil")
            struct WhenSha1ReturnsNilTests {
                @Test("should return NO_DEVICE_ID_FOUND")
                func testReturnsNoDeviceIdFound() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = nil
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())
                    #expect(handler.ckp() == "NO_DEVICE_ID_FOUND")
                }
            }

            @Suite("When sha1() returns a non-nil value")
            struct WhenSha1ReturnsNonNilValueTests {
                @Test("should return a non-empty value")
                func testReturnsNonEmptyValue() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = nil
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())
                    #expect(!handler.ckp().isEmpty)
                }
            }
        }

        @Suite("When idfvUUID is an empty String")
        struct WhenIdfvUUIDIsEmptyStringTests {
            @Suite("When sha1() returns nil")
            struct WhenSha1ReturnsNilTests {
                @Test("should return NO_DEVICE_ID_FOUND")
                func testReturnsNoDeviceIdFound() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = ""
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())
                    #expect(handler.ckp() == "NO_DEVICE_ID_FOUND")
                }
            }

            @Suite("When sha1() returns a non-nil value")
            struct WhenSha1ReturnsNonNilValueTests {
                @Test("should return a non-empty value")
                func testReturnsNonEmptyValue() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = ""
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())
                    #expect(!handler.ckp().isEmpty)
                }
            }
        }

        @Suite("When idfvUUID equals 00000000-0000-0000-0000-000000000000")
        struct WhenIdfvUUIDEqualsZeroTests {
            @Suite("When sha1() returns nil")
            struct WhenSha1ReturnsNilTests {
                @Test("should return NO_DEVICE_ID_FOUND")
                func testReturnsNoDeviceIdFound() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = "00000000-0000-0000-0000-000000000000"
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())
                    #expect(handler.ckp() == "NO_DEVICE_ID_FOUND")
                }
            }

            @Suite("When sha1() returns a non-nil value")
            struct WhenSha1ReturnsNonNilValueTests {
                @Test("should return a non-empty value")
                func testReturnsNonEmptyValue() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = "00000000-0000-0000-0000-000000000000"
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())
                    #expect(!handler.ckp().isEmpty)
                }
            }
        }

        @Suite("When idfvUUID equals 123e4567-e89b-12d3-a456-426652340000")
        struct WhenIdfvUUIDEqualsSpecificValueTests {
            @Suite("When sha1() returns nil")
            struct WhenSha1ReturnsNilTests {
                @Test("should return NO_DEVICE_ID_FOUND")
                func testReturnsNoDeviceIdFound() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = "123e4567-e89b-12d3-a456-426652340000"
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: NilHasher())
                    #expect(handler.ckp() == "NO_DEVICE_ID_FOUND")
                }
            }

            @Suite("When sha1() returns a non-nil value")
            struct WhenSha1ReturnsNonNilValueTests {
                @Test("should return 428529fb27609e73dce768588ba6f1a1c1647451")
                func testReturnsExpectedHash() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = "123e4567-e89b-12d3-a456-426652340000"
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())
                    #expect(handler.ckp() == "428529fb27609e73dce768588ba6f1a1c1647451")
                }

                @Test("should return 98f43051f367e16779c645e32fb731368e9fa792")
                func testReturnsExpectedHashForUppercaseUUID() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = "D552F5FB-270F-4236-8FE9-11C14A353E71"
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())
                    #expect(handler.ckp() == "98f43051f367e16779c645e32fb731368e9fa792")
                }

                @Test("should return ba63e16988f226917060c08f19e060f119509e9c")
                func testReturnsExpectedHashForAnotherUUID() {
                    let deviceIdentifierMock = DeviceMock()
                    deviceIdentifierMock.idfvUUID = "8D0E6370-A418-4A3C-81E1-6211D9C74071"
                    let handler = DeviceIdentifierHandler(device: deviceIdentifierMock, hasher: SecureHasher())
                    #expect(handler.ckp() == "ba63e16988f226917060c08f19e060f119509e9c")
                }
            }
        }
    }
}
