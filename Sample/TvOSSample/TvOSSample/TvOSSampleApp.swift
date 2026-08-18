import SwiftUI
import RakutenAnalytics

@main
struct TvOSSampleApp: App {
    init() {
        AnalyticsManager.shared().set(loggingLevel: .debug)
        RAnalyticsRATTracker.shared().set(batchingDelay: 15)
        AnalyticsManager.shared().set(endpointURL: URL(string: "https://check.rat.rakuten.co.jp/"))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
