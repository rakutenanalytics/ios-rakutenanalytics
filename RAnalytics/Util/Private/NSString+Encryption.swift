import Foundation
import CommonCrypto.CommonDigest

private extension NSString {
    @objc func ratEncrypt() -> NSString? {
        guard let ratData = nsdata(using: String.Encoding.utf8.rawValue) else { return nil }
        return ratData.digest.hexString
    }

    func nsdata(using encoding: UInt) -> NSData? {
        data(using: encoding) as NSData?
    }
}

private extension NSData {
    var digest: NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(bytes, UInt32(length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    var hexString: NSString {
        var bytes = [UInt8](repeating: 0, count: length)
        getBytes(&bytes, length: length)
        return bytes.map { String(format: "%02x", $0) }.joined() as NSString
    }
}
