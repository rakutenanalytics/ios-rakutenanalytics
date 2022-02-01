import Foundation

// MARK: - KeychainHandleable

protocol KeychainHandleable {
    func item(for label: String) -> KeychainResult
    func set(creationDate: Date?, for label: String)
    func creationDate(for reference: CFTypeRef?) -> Date?
}

// MARK: - KeychainResult

final class KeychainResult {
    let result: CFTypeRef?
    let status: OSStatus
    init(result: CFTypeRef?, status: OSStatus) {
        self.result = result
        self.status = status
    }
}

// MARK: - KeychainHandler

final class KeychainHandler {
    private func query(for label: String) -> [String: Any] {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrLabel as String] = label
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return query
    }
}

extension KeychainHandler: KeychainHandleable {
    func item(for label: String) -> KeychainResult {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query(for: label) as CFDictionary, &result)
        return KeychainResult(result: result, status: status)
    }

    func set(creationDate: Date?, for label: String) {
        var mutableQuery = query(for: label)
        mutableQuery[kSecAttrCreationDate as String] = creationDate
        SecItemAdd(mutableQuery as CFDictionary, nil)
    }

    func creationDate(for reference: CFTypeRef?) -> Date? {
        guard let values = reference as? [CFString: Any] else {
            return nil
        }
        return values[kSecAttrCreationDate] as? Date
    }
}
