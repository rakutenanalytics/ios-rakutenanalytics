import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

private let reservedQueryItemNames = [PayloadParameterKeys.ref,
                                      CpParameterKeys.Ref.accountIdentifier,
                                      CpParameterKeys.Ref.applicationIdentifier,
                                      CpParameterKeys.Ref.link,
                                      CpParameterKeys.Ref.component]

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

        guard let accString = queryItems.first(where: { $0.name == CpParameterKeys.Ref.accountIdentifier })?.value,
              let accountIdentifier = Int64(accString),
              accountIdentifier > 0 else {
            return nil
        }
        self.accountIdentifier = accountIdentifier

        guard let aidString = queryItems.first(where: { $0.name == CpParameterKeys.Ref.applicationIdentifier })?.value,
              let applicationIdentifier = Int64(aidString),
              applicationIdentifier > 0 else {
            return nil
        }
        self.applicationIdentifier = applicationIdentifier

        link = queryItems.first(where: { $0.name == CpParameterKeys.Ref.link })?.value

        component = queryItems.first(where: { $0.name == CpParameterKeys.Ref.component })?.value

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

        if let encodedKey = CpParameterKeys.Ref.accountIdentifier.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = "\(accountIdentifier)".addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = CpParameterKeys.Ref.applicationIdentifier.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = "\(applicationIdentifier)".addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = CpParameterKeys.Ref.link.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = link?.addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = CpParameterKeys.Ref.component.addEncodingForRFC3986UnreservedCharacters(),
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
