import Foundation
import CommonCrypto

extension Data {
    var hexString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
