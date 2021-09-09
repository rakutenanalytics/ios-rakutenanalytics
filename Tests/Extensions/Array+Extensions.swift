import Foundation

extension Array where Element == Data {
    func deserialize() -> [[String: Any]] {
        compactMap { data in
            try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any]
        }
    }
}
