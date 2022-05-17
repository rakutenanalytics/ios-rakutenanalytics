import Foundation
import CommonCrypto.CommonDigest

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
