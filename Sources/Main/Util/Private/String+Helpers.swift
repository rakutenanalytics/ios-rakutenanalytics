import Foundation

extension String {
    func remove(suffix: String) -> String {
        guard self.contains(suffix) else {
            return self
        }
        return replacingOccurrences(of: suffix, with: "")
    }
}
