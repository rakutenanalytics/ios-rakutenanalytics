import Foundation

extension AnalyticsManager {
    func trackReferralApp(url: URL, sourceApplication: String? = nil) {
        guard let model = ReferralAppModel(url: url, sourceApplication: sourceApplication) else {
            return
        }
        launchCollector.referralTracking = .referralApp(model)
        process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.applink, parameters: nil))
        launchCollector.referralTracking = .none
        
        /// Reset the origin to RAnalyticsInternalOrigin for the next page visit after each external
        /// call or push notification.
        AnalyticsManager.shared().launchCollector.origin = .inner
    }
}

// MARK: - ReferralAppTrackable

extension AnalyticsManager: ReferralAppTrackable {
    func tryToTrackReferralApp(with url: URL?, sourceApplication: String?) {
        if let url = url {
            launchCollector.origin = .external
            trackReferralApp(url: url, sourceApplication: sourceApplication)
        }
    }

    func tryToTrackReferralApp(with webpageURL: URL?) {
        if let url = webpageURL {
            launchCollector.origin = .external
            trackReferralApp(url: url, sourceApplication: nil)
        }
    }
}
