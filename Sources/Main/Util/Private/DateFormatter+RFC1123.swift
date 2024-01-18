import Foundation

extension DateFormatter {
    static let rfc1123DateFormatter: DateFormatter = {
        let rfc1123 = "EEE, dd MMM yyyy HH:mm:ss z"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = rfc1123
        return formatter
    }()
}
