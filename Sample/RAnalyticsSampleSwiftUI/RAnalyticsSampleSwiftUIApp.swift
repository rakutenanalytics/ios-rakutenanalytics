import SwiftUI
import RakutenAnalytics
import Foundation

@main
struct RAnalyticsSampleSwiftUIApp: App {
    init() {
        AnalyticsManager.shared().shouldTrackEventHandler = { _ in
            true
        }
        AnalyticsManager.shared().set(loggingLevel: .debug)
        AnalyticsManager.shared().enableAppToWebTracking = true
        AnalyticsManager.shared().set(endpointURL: URL(string: "https://rat.rakuten.co.jp/"))
        RAnalyticsRATTracker.shared().set(batchingDelay: 15)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
