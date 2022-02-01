import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

private let reservedQueryItemNames = [PayloadParameterKeys.ref,
                                      PayloadParameterKeys.refAccountIdentifier,
                                      PayloadParameterKeys.refApplicationIdentifier,
                                      PayloadParameterKeys.refLink,
                                      PayloadParameterKeys.refComponent]

// MARK: - Init with URL

extension ReferralAppModel {
    init?(url: URL, sourceApplication: String?) {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              !queryItems.isEmpty else {
            return nil
        }

        guard let bundleIdentifier = sourceApplication ?? (queryItems.first(where: { $0.name == PayloadParameterKeys.ref })?.value) else {
            return nil
        }
        self.bundleIdentifier = bundleIdentifier

        guard let accString = queryItems.first(where: { $0.name == PayloadParameterKeys.refAccountIdentifier })?.value,
              let accountIdentifier = Int64(accString),
              accountIdentifier > 0 else {
            return nil
        }
        self.accountIdentifier = accountIdentifier

        guard let aidString = queryItems.first(where: { $0.name == PayloadParameterKeys.refApplicationIdentifier })?.value,
              let applicationIdentifier = Int64(aidString),
              applicationIdentifier > 0 else {
            return nil
        }
        self.applicationIdentifier = applicationIdentifier

        link = queryItems.first(where: { $0.name == PayloadParameterKeys.refLink })?.value

        component = queryItems.first(where: { $0.name == PayloadParameterKeys.refComponent })?.value

        if !queryItems.isEmpty {
            customParameters = queryItems.reduce(into: [:]) { params, queryItem in
                if !reservedQueryItemNames.contains(queryItem.name) {
                    params?[queryItem.name] = queryItem.value
                }
            }
        }
    }
}

// MARK: - Query

extension ReferralAppModel {
    var query: String {
        var queryBuilder = [String]()

        if let encodedKey = PayloadParameterKeys.refAccountIdentifier.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = "\(accountIdentifier)".addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = PayloadParameterKeys.refApplicationIdentifier.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = "\(applicationIdentifier)".addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = PayloadParameterKeys.refLink.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = link?.addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = PayloadParameterKeys.refComponent.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = component?.addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let customParameters = customParameters {
            customParameters.forEach { item in
                if let encodedKey = item.key.addEncodingForRFC3986UnreservedCharacters(),
                   let encodedValue = item.value.addEncodingForRFC3986UnreservedCharacters() {
                    queryBuilder.append("\(encodedKey)=\(encodedValue)")
                }
            }
        }

        return queryBuilder.joined(separator: "&")
    }
}
