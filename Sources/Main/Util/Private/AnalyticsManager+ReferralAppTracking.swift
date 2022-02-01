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
}
