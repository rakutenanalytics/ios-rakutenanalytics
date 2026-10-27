import Foundation

/// Values and helpers for Mobile Privacy Control RAT payload fields.
enum PrivacyControlPayload {
    /// Whether device-information category data (including `ckp`, model, UA, …) may be attached to RAT payloads.
    ///
    /// Same rule as RAT install/update `cp` device gating and root-level device-information parameters.
    static func allowsDeviceInformationOnRatPayload(bundle: EnvironmentBundle,
                                                    consentStore: DataCollectionConsentReadable) -> Bool {
        !bundle.isPrivacyControlEnabled || consentStore.isEnabled(.deviceInformation)
    }

    /// Builds `privacy_mode` for the **root** RAT JSON on every event (RAT tracker + Geo `loc`): four characters
    /// `0`/`1` in spec order — location, mobile network, device information, user information.
    /// When the build-time privacy flag is off, returns ``RATConstants/PrivacyMode/defaultFullCollection`` (default full collection).
    static func privacyModeString(bundle: EnvironmentBundle, consentStore: DataCollectionConsentReadable) -> String {
        if !bundle.isPrivacyControlEnabled {
            return RATConstants.PrivacyMode.defaultFullCollection
        }
        return DataCollectionType.individualTypes.map { consentStore.isEnabled($0) ? "1" : "0" }.joined()
    }
}
