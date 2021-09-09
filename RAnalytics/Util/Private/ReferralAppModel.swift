import Foundation

struct ReferralAppModel: Hashable {
    /// The referral app's bundle identifier
    let bundleIdentifier: String

    /// The referral app's RAT account identifier
    let accountIdentifier: Int

    /// The referral app's RAT application identifier
    let applicationIdentifier: Int

    /// The unique identifier of the referral trigger
    let link: String?

    /// The referral app's component
    let component: String?

    /// The custom parameters
    var customParameters: [String: String]?
}

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
              let accountIdentifier = Int(accString) else {
            return nil
        }
        self.accountIdentifier = accountIdentifier

        guard let aidString = queryItems.first(where: { $0.name == PayloadParameterKeys.refApplicationIdentifier })?.value,
              let applicationIdentifier = Int(aidString) else {
            return nil
        }
        self.applicationIdentifier = applicationIdentifier

        link = queryItems.first(where: { $0.name == PayloadParameterKeys.refLink })?.value

        component = queryItems.first(where: { $0.name == PayloadParameterKeys.refComponent })?.value

        if !queryItems.isEmpty {
            customParameters = queryItems.reduce(into: [:]) { params, queryItem in
                if !queryItem.name.starts(with: PayloadParameterKeys.ref) {
                    params?[queryItem.name] = queryItem.value
                }
            }
        }
    }
}
