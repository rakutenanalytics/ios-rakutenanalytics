import Foundation

extension AnalyticsManager {
    func trackReferralApp(url: URL, sourceApplication: String? = nil) {
        guard let model = ReferralAppModel(url: url, sourceApplication: sourceApplication) else {
            return
        }
        launchCollector.referralTracking = .referralApp(model)
        process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil))
        launchCollector.referralTracking = .none
    }

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
