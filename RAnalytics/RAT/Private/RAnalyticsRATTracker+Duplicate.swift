import Foundation

extension RAnalyticsRATTracker {
    /// Generate and pass payloads iff RATDuplicateAccounts are specified to a handler
    func duplicateEvent(named eventName: String, with payload: NSMutableDictionary, sender: Sendable) {
        if let runtimeHandler = shouldDuplicateRATEventHandler {
            duplicateAccounts.forEach { account in
                if runtimeHandler(eventName, account.accountId) {
                    sender.send(jsonObject: payload.duplicate(for: account))
                }
            }
        } else {
            duplicateAccounts.forEach { account in
                if !(account.disabledEvents?.contains(eventName) ?? false) {
                    sender.send(jsonObject: payload.duplicate(for: account))
                }
            }
        }
    }
}

private extension NSMutableDictionary {
    func duplicate(for account: RATAccount) -> NSMutableDictionary {
        guard let duplicatePayload = mutableCopy() as? NSMutableDictionary else {
            return self
        }
        duplicatePayload["acc"] = account.accountId
        duplicatePayload["aid"] = account.applicationId
        return duplicatePayload
    }
}
