import Foundation
import UIKit
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

struct DeviceIdentifierHandler {
    private let defaultDeviceIdentifier = "NO_DEVICE_ID_FOUND"
    private let zeroesAndHyphens = CharacterSet(charactersIn: "0-")
    private let device: DeviceCapability

    init(device: DeviceCapability) {
        self.device = device
    }

    /// - Returns: The Identifier for vendor's UUID value formatted for `ckp`.
    ///
    /// - Note: If the ckp formatting fails, `NO_DEVICE_ID_FOUND` is returned.
    func ckp() -> String {
        var idfvUUID = device.idfvUUID

        let result = idfvUUID?.trimmingCharacters(in: zeroesAndHyphens)
        if result.isEmpty {
            // Filter out nil, empty, or zeroed strings (e.g. "00000000-0000-0000-0000-000000000000")
            // We don't have many options here, beside generating an id.
            idfvUUID = UUID().uuidString
        }

        let idfvUUIDSha1 = idfvUUID?.data(using: .utf8)?.sha1

        return idfvUUIDSha1?.hexString ?? defaultDeviceIdentifier
    }
}
