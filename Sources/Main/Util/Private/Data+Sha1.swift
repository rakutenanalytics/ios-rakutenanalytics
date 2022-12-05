import Foundation
import CommonCrypto.CommonDigest

protocol SecureHashable {
    func sha1(value: String) -> Data?
}

struct SecureHasher: SecureHashable {
    func sha1(value: String) -> Data? {
        guard let data = value.data(using: .utf8),
              let notOptionalSha1 = data.sha1 else {
            return nil
        }
        return notOptionalSha1
    }
}

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
