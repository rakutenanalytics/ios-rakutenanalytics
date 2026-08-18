import UIKit

// MARK: - ReferralAppTrackable

extension ReferralAppTrackable {
    func handleIncomingURLContexts(_ contexts: Set<UIOpenURLContext>) {
        if contexts.isEmpty {
            tryToTrackReferralApp(with: UIOpenURLContext.DefaultValues.url,
                                  sourceApplication: UIOpenURLContext.DefaultValues.sourceApplication)
            return
        }

        for context in contexts {
            tryToTrackReferralApp(with: context.url,
                                  sourceApplication: context.options.sourceApplication)
        }
    }

    func handleIncomingConnectionOptions(_ options: UIScene.ConnectionOptions) {
        handleIncomingURLContexts(options.urlContexts)

        if options.userActivities.isEmpty,
           let webpageURL = UIScene.ConnectionOptions.DefaultValues.webpageURL {
            tryToTrackReferralApp(with: webpageURL)
            return
        }

        for activity in options.userActivities {
            handleIncomingUserActivity(activity)
        }
    }

    func handleIncomingUserActivity(_ userActivity: NSUserActivity) {
        tryToTrackReferralApp(with: userActivity.webpageURL)
    }

    /// Handles cold-launch deep links injected through test-only default values.
    func handleIncomingColdLaunchFromInjectedValues() {
        handleIncomingURLContexts([])
        if let webpageURL = UIScene.ConnectionOptions.DefaultValues.webpageURL {
            tryToTrackReferralApp(with: webpageURL)
        }
    }
}

// MARK: - AnalyticsManager

extension AnalyticsManager {
    func handleIncomingURLContextsWithLogging(_ contexts: Set<UIOpenURLContext>) {
        if contexts.isEmpty {
            if let url = UIOpenURLContext.DefaultValues.url {
                RLogger.verbose(message: "Tracking incoming URL from scene(openURLContexts:): \(url.absoluteString), "
                    + "sourceApplication=\(String(describing: UIOpenURLContext.DefaultValues.sourceApplication))")
            }
            handleIncomingURLContexts(contexts)
            return
        }

        for context in contexts {
            RLogger.verbose(message: "Tracking incoming URL from scene(openURLContexts:): \(context.url.absoluteString), "
                + "sourceApplication=\(String(describing: context.options.sourceApplication))")
        }
        handleIncomingURLContexts(contexts)
    }

    func handleIncomingConnectionOptionsWithLogging(_ options: UIScene.ConnectionOptions) {
        for context in options.urlContexts {
            RLogger.verbose(message: "Tracking incoming URL from scene(willConnectTo:options:): \(context.url.absoluteString), "
                + "sourceApplication=\(String(describing: context.options.sourceApplication))")
        }
        for activity in options.userActivities {
            if let url = activity.webpageURL {
                RLogger.verbose(message: "Tracking incoming universal link from scene(willConnectTo:options:): \(url.absoluteString)")
            }
        }
        handleIncomingConnectionOptions(options)
    }

    func handleIncomingUserActivityWithLogging(_ userActivity: NSUserActivity) {
        if let url = userActivity.webpageURL {
            RLogger.verbose(message: "Tracking incoming universal link from scene(continue:): \(url.absoluteString)")
        }
        handleIncomingUserActivity(userActivity)
    }
}

extension UIScene.ConnectionOptions {
    /// Test-only injection point for cold-launch universal link simulation.
    ///
    /// - Warning: For internal testing only.
    enum DefaultValues {
        static var webpageURL: URL?
    }
}
