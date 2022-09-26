import Foundation

// MARK: - KeychainHandleable

protocol KeychainHandleable {
    func item(for label: String) -> KeychainResult
    func set(creationDate: Date?, for label: String)
    func creationDate(for reference: CFTypeRef?) -> Date?
    func string(for key: String) throws -> String?
    func set(value: String?, for key: String) throws
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
    private let bundle: EnvironmentBundle

    init(bundle: EnvironmentBundle) {
        self.bundle = bundle
    }

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

    /// Return a stored string value from the Keychain or `nil`.
    ///
    /// - Parameter key: the associated key of the value to retrieve.
    ///
    /// - Throws an error if the bundle identfier is nil.
    ///
    /// - Note:
    ///
    /// Duplicate of https://github.com/rakutentech/macos-push-tester/blob/master/PusherMainView/PusherMainView/Keychain.swift
    ///
    /// Additional features:
    ///     - The function throws errors
    ///     - The function is not static
    ///
    /// Should be moved to RSDKUtils.
    func string(for key: String) throws -> String? {
        guard let service = bundle.bundleIdentifier else {
            throw ErrorConstants.keychainBundleError
        }

        let queryLoad: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let resultCodeLoad = SecItemCopyMatching(queryLoad as CFDictionary, &result)
        if resultCodeLoad == errSecSuccess,
           let resultVal = result as? Data,
           let keyValue = String(data: resultVal, encoding: .utf8) {
            return keyValue
        }
        return nil
    }

    /// Store a string value in the Keychain.
    ///
    /// - Parameters:
    ///    - value: the value to store
    ///    - key: the associated key of the value to store
    ///
    /// - Throws an error if the bundle identfier is nil.
    ///
    /// - Note:
    ///
    /// Duplicate of https://github.com/rakutentech/macos-push-tester/blob/master/PusherMainView/PusherMainView/Keychain.swift
    ///
    /// Additional features:
    ///     - The function throws errors
    ///     - The function is not static
    ///     - `forKey` label is replaced by `for`
    ///
    /// Should be moved to RSDKUtils.
    func set(value: String?, for key: String) throws {
        guard let service = bundle.bundleIdentifier else {
            throw ErrorConstants.keychainBundleError
        }

        let queryFind: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        guard let valueNotNil = value, let data = valueNotNil.data(using: .utf8) else {
            SecItemDelete(queryFind as CFDictionary)
            return
        }

        let updatedAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        var resultCode = SecItemUpdate(queryFind as CFDictionary, updatedAttributes as CFDictionary)

        if resultCode == errSecItemNotFound {
            let queryAdd: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]

            resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
        }

        if resultCode != errSecSuccess {
            throw AnalyticsError.detailedError(domain: ErrorDomain.keychainHandlerErrorDomain,
                                               code: ErrorCode.keychainHandlerFailure.rawValue,
                                               description: ErrorDescription.keychainHandlerFailed,
                                               reason: "Unable to store data \(resultCode)").nsError()
        }
    }
}
