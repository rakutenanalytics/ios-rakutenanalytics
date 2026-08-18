import Foundation

extension AnalyticsManager {
    func trackReferrals(url: URL, sourceApplication: String? = nil) {
        // Track Rakuten App to App referral if that's the case
        if !trackReferralApp(url: url, sourceApplication: sourceApplication) {
            // Track external referrals if it's not an internal referral
            trackExternalReferral(url: url)
        }
        
        // Reset the origin to RAnalyticsInternalOrigin for the next page visit after each external
        // call or push notification.
        AnalyticsManager.shared().launchCollector.origin = .inner
    }
    
    func trackExternalReferral(url: URL) {
        launchCollector.referralTracking = .externalReferral(url)
        process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.externalReferrer, parameters: nil))
        launchCollector.referralTracking = .none
    }
    
    func trackReferralApp(url: URL, sourceApplication: String? = nil) -> Bool {
        guard let model = ReferralAppModel(url: url, sourceApplication: sourceApplication) else {
            RLogger.debug(message: "ReferralAppModel could not be created for url=\(url.absoluteString), "
                + "sourceApplication=\(String(describing: sourceApplication)). "
                + "Ensure referral URLs include the required query parameters and, for scene-based apps, "
                + "a `ref` parameter when sourceApplication is unavailable.")
            return false
        }
        launchCollector.referralTracking = .referralApp(model)
        process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.applink, parameters: nil))
        launchCollector.referralTracking = .none
        return true
    }
}

// MARK: - ReferralAppTrackable

extension AnalyticsManager: ReferralAppTrackable {
    func tryToTrackReferralApp(with url: URL?, sourceApplication: String?) {
        if let url = url {
            launchCollector.origin = .external
            trackReferrals(url: url, sourceApplication: sourceApplication)
        }
    }

    func tryToTrackReferralApp(with webpageURL: URL?) {
        if let url = webpageURL {
            launchCollector.origin = .external
            trackReferrals(url: url)
        }
    }
}
