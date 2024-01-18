import Foundation

extension RAnalyticsRATTracker {
    /// Generate and pass payloads iff RATDuplicateAccounts are specified to a handler
    ///
    /// - Parameters:
    ///     - eventName: the event name.
    ///     - payload: the RAT payload.
    ///     - excludedAccount: the excluded RAT account. Note: the payload won't be sent to the excluded RAT account.
    ///     - sender: the sender.
    func duplicateEvent(named eventName: String, with payload: NSMutableDictionary, exclude excludedAccount: RATAccount? = nil, sender: Sendable) {
        if let runtimeHandler = shouldDuplicateRATEventHandler {
            duplicateAccounts.filter { $0 != excludedAccount }.forEach { account in
                if runtimeHandler(eventName, account.accountId) {
                    sender.send(jsonObject: payload.duplicate(for: account))
                }
            }
        } else {
            duplicateAccounts.filter { $0 != excludedAccount }.forEach { account in
                if !(account.disabledEvents?.contains(eventName) ?? false) {
                    sender.send(jsonObject: payload.duplicate(for: account))
                }
            }
        }
    }
}

extension NSMutableDictionary {
    /// Duplicate the RAT Payload for a given RAT account.
    ///
    /// - Parameters:
    ///     - account: the RAT account.
    ///
    /// - Returns: the duplicate payload.
    func duplicate(for account: RATAccount) -> NSMutableDictionary {
        guard let duplicatePayload = mutableCopy() as? NSMutableDictionary else {
            return self
        }
        duplicatePayload[PayloadParameterKeys.acc] = account.accountId
        duplicatePayload[PayloadParameterKeys.aid] = account.applicationId
        return duplicatePayload
    }
}
