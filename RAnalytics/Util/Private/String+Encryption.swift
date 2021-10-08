import Foundation
import CommonCrypto.CommonDigest
import RSDKUtils

extension String {
    var ratEncrypt: String? {
        guard let ratData = data(using: .utf8) else { return nil }
        return ratData.digest.hexString
    }
}

private extension Data {
    var digest: Data {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)

        var bytes = [UInt8](repeating: 0, count: count)
        (self as NSData).getBytes(&bytes, length: count)

        CC_SHA256(bytes, UInt32(count), &hash)

        return Data(bytes: hash, count: digestLength)
    }
}
