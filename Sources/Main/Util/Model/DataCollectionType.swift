import Foundation

/// Data collection category for runtime privacy control (Mobile Privacy Control specification).
///
/// When the build-time privacy flag is off, ``AnalyticsManager/set(dataCollection:enabled:)`` is ignored
/// and all categories are collected. When it is on, use ``AnalyticsManager/set(dataCollection:enabled:)``
/// and ``AnalyticsManager/isDataCollectionEnabled(dataCollection:)`` for location,
/// mobile network, device information, user information, and the aggregate ``all`` category.
///
/// Unset stored consent for granular categories is treated as not granted.
/// Consent controls **category data in payloads and related SDK behavior**, not whether tracking is
/// globally disabled until this API is called.
public enum DataCollectionType: Int, CaseIterable, Sendable {
    /// Location data (loc, GeoTracker events).
    case location

    /// Mobile network parameters (mcn, mcnd, mnetw, mnetwd, online).
    case mobileNetwork

    /// Device information (dln, model, res, mori, powerstatus, mbat, ckp, cka, tzo, ua, ua_enriched, device_per, mos) and app-to-web tracking cookie (`ra_uid`).
    case deviceInformation

    /// User information: easy identifier (`easyid`) and Rp cookie behavior for RAT requests.
    case userInformation

    /// All granular categories at once.
    case all

    /// Categories persisted and toggled independently (excludes ``all``).
    public static var individualTypes: [DataCollectionType] {
        [.location, .mobileNetwork, .deviceInformation, .userInformation]
    }
}
