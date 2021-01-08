import Foundation

// MARK: - KeychainHandleable

@objc public protocol KeychainHandleable {
    func item(for label: String) -> KeychainResult
    func set(creationDate: Date?, for label: String)
    func creationDate(for reference: CFTypeRef?) -> Date?
}

// MARK: - KeychainResult

public final class KeychainResult: NSObject {
    let result: CFTypeRef?
    let status: OSStatus
    public init(result: CFTypeRef?, status: OSStatus) {
        self.result = result
        self.status = status
        super.init()
    }
}

// MARK: - KeychainHandler

public final class KeychainHandler: NSObject {
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
    public func item(for label: String) -> KeychainResult {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query(for: label) as CFDictionary, &result)
        return KeychainResult(result: result, status: status)
    }

    public func set(creationDate: Date?, for label: String) {
        var mutableQuery = query(for: label)
        mutableQuery[kSecAttrCreationDate as String] = creationDate
        SecItemAdd(mutableQuery as CFDictionary, nil)
    }

    public func creationDate(for reference: CFTypeRef?) -> Date? {
        guard let values = reference as? [CFString: Any] else {
            return nil
        }
        return values[kSecAttrCreationDate] as? Date
    }
}
