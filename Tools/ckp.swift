#!/usr/bin/swift

import Foundation
import CommonCrypto

extension Data {
    var sha1: Data? {
        guard !isEmpty else {
            return nil
        }

        let digestLength = Int(CC_SHA1_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)

        var bytes = [UInt8](repeating: 0, count: count)
        (self as NSData).getBytes(&bytes, length: count)

        CC_SHA1(bytes, CC_LONG(count), &hash)

        return Data(bytes: hash, count: digestLength)
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}

struct DeviceIdentifierHandler {
    private static let zeroesAndHyphens = CharacterSet(charactersIn: "0-")

    /// - Returns: The Identifier for vendor's UUID value formatted for `ckp`.
    static func ckp(idfv: String) -> String? {
        var idfvUUID = idfv

        let result = idfvUUID.trimmingCharacters(in: zeroesAndHyphens)
        if result.isEmpty {
            // Filter out nil, empty, or zeroed strings (e.g. "00000000-0000-0000-0000-000000000000")
            // We don't have many options here, beside generating an id.
            idfvUUID = UUID().uuidString
        }

        let idfvUUIDSha1 = idfvUUID.data(using: .utf8)?.sha1

        return idfvUUIDSha1?.hexString
    }
}

// MARK: - Main program

guard CommandLine.arguments.count == 2 else {
    print("Error: This script accepts only one argument.")
    exit(1)
}

let idfv = CommandLine.arguments[1]

guard let uuid = UUID(uuidString: idfv) else {
    print("Error: The IDFV format is invalid.")
    exit(1)
}

guard let ckp = DeviceIdentifierHandler.ckp(idfv: idfv) else {
    print("Error: An occured while generating the CKP.")
    exit(1)
}

print("\(ckp)")
