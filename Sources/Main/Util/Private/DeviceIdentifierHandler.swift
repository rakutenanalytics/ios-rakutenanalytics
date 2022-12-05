import Foundation
import UIKit
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

/// CKP generator.
struct DeviceIdentifierHandler {
    private let defaultDeviceIdentifier = "NO_DEVICE_ID_FOUND"
    private let zeroesAndHyphens = CharacterSet(charactersIn: "0-")
    private let device: DeviceCapability
    private let hasher: SecureHashable

    /// Creates an instance of `DeviceIdentifierHandler`.
    ///
    /// - Parameters:
    ///    - device: an instance conforming to `DeviceCapability` protocol
    ///    - hasher: an instance conforming to `SecureHashable` protocol
    init(device: DeviceCapability, hasher: SecureHashable) {
        self.device = device
        self.hasher = hasher
    }

    /// - Returns: The Identifier for vendor's UUID value formatted for `ckp`.
    ///
    /// - Note: If the ckp formatting fails, `NO_DEVICE_ID_FOUND` is returned.
    func ckp() -> String {
        var idfvUUID: String = device.idfvUUID ?? ""

        if idfvUUID.isEmpty || idfvUUID.trimmingCharacters(in: zeroesAndHyphens).isEmpty {
            idfvUUID = UUID().uuidString
        }

        guard let idfvUUIDSha1 = hasher.sha1(value: idfvUUID) else {
            return defaultDeviceIdentifier
        }

        return idfvUUIDSha1.hexString
    }
}
