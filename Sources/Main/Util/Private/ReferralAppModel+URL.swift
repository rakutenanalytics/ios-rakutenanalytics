import Foundation

private let reservedQueryItemNames = [PayloadParameterKeys.ref,
                                      DeepLinkParameterKeys.accountIdentifier,
                                      DeepLinkParameterKeys.applicationIdentifier,
                                      PayloadParameterKeys.Cp.refLink,
                                      PayloadParameterKeys.Cp.refComp]

// MARK: - Init with URL

extension ReferralAppModel {
    init?(url: URL, sourceApplication: String?) {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              !queryItems.isEmpty else {
            return nil
        }

        guard let bundleIdentifier = (queryItems.first(where: { $0.name == PayloadParameterKeys.ref })?.value) ?? sourceApplication else {
            return nil
        }
        self.bundleIdentifier = bundleIdentifier

        guard let accString = queryItems.first(where: { $0.name == DeepLinkParameterKeys.accountIdentifier })?.value,
              let accountIdentifier = Int64(accString),
              accountIdentifier > 0 else {
            return nil
        }
        self.accountIdentifier = accountIdentifier

        guard let aidString = queryItems.first(where: { $0.name == DeepLinkParameterKeys.applicationIdentifier })?.value,
              let applicationIdentifier = Int64(aidString),
              applicationIdentifier > 0 else {
            return nil
        }
        self.applicationIdentifier = applicationIdentifier

        link = queryItems.first(where: { $0.name == PayloadParameterKeys.Cp.refLink })?.value

        component = queryItems.first(where: { $0.name == PayloadParameterKeys.Cp.refComp })?.value

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
    public var query: String {
        var queryBuilder = [String]()

        if let encodedKey = DeepLinkParameterKeys.accountIdentifier.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = "\(accountIdentifier)".addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = DeepLinkParameterKeys.applicationIdentifier.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = "\(applicationIdentifier)".addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = PayloadParameterKeys.Cp.refLink.addEncodingForRFC3986UnreservedCharacters(),
           let encodedValue = link?.addEncodingForRFC3986UnreservedCharacters() {
            queryBuilder.append("\(encodedKey)=\(encodedValue)")
        }

        if let encodedKey = PayloadParameterKeys.Cp.refComp.addEncodingForRFC3986UnreservedCharacters(),
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
