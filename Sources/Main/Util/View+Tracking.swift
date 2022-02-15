import SwiftUI

@available(iOS 13.0, *)
extension View {
    /// Use this function in order to track the page visit event when a SwiftUI View appears.
    ///
    /// - Note: This function calls SwiftUI's `onAppear` internally.
    /// https://developer.apple.com/documentation/SwiftUI/AnyView/onAppear%28perform:%29
    ///
    /// - Parameters:
    ///    - pageName: The page name.
    ///    - action: The action to perform
    ///
    /// - Returns: the appeared view.
    ///
    /// - Example:
    ///    struct ContentView: View {
    ///        var body: some View {
    ///            NavigationView {
    ///                VStack {
    ///                    NavigationLink(destination: PageView()) {
    ///                        Text("Page 1")
    ///                    }
    ///
    ///                    NavigationLink(destination: PageView()) {
    ///                        Text("Page 2")
    ///                    }
    ///
    ///                }.rviewOnAppear(pageName: "contentView") {
    ///                }
    ///            }
    ///        }
    ///    }
    public func rviewOnAppear(pageName: String, perform action: (() -> Void)? = nil) -> some View {
        onAppear {
            AnalyticsManager.shared().launchCollector.trackPageVisit(with: .swiftuiPage(pageName: pageName))
            action?()
        }
    }
}
