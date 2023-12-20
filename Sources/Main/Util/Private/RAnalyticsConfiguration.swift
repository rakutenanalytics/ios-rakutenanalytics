// MARK: - RAnalyticsConfiguration

struct RAnalyticsConfiguration {
    let disabledEvents: [String]?
    let duplicateAccounts: [RATAccount]?
}

extension RAnalyticsConfiguration: Codable {
    private enum CodingKeys: String, CodingKey {
        case disabledEvents = "RATDisabledEventsList"
        case duplicateAccounts = "RATDuplicateAccounts"
    }
}

// MARK: - RATAccount

struct RATAccount {
    let accountId: Int64
    let applicationId: Int64
    let disabledEvents: [String]?
}

extension RATAccount: Codable {
    enum CodingKeys: String, CodingKey {
        case accountId = "RATAccountIdentifier"
        case applicationId = "RATAppIdentifier"
        case disabledEvents = "RATNonDuplicatedEventsList"
    }
}

extension RATAccount: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.accountId == rhs.accountId
            && lhs.applicationId == rhs.applicationId
    }
}
