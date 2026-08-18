import SwiftUI
import RakutenAnalytics

struct ContentView: View {
    @State private var customEventCount = 0

    var body: some View {
        NavigationView {
            List {
                Section("Automatic tracking") {
                    NavigationLink("SwiftUI page visit") {
                        SwiftUIPageView()
                    }
                    NavigationLink("UIKit page visit") {
                        UIKitPageHostView()
                    }
                }

                Section("Manual tracking") {
                    Button("Send custom event") {
                        customEventCount += 1
                        // RAT `etype` comes from `eventName`, not from `_analytics_custom`.
                        let event = RAnalyticsEvent(
                            name: RAnalyticsEvent.Name.custom,
                            parameters: [
                                RAnalyticsEvent.Parameter.eventName: "tvos_sample_button_tap",
                                RAnalyticsEvent.Parameter.eventData: [
                                    "count": customEventCount
                                ]
                            ]
                        )
                        let processed = AnalyticsManager.shared().process(event)
                        if !processed {
                            print("Custom event was not processed — check eventName and RAT configuration.")
                        }
                    }
                }

                Section("SDK state") {
                    Text("Device ID: \(AnalyticsManager.shared().deviceIdentifier)")
                        .font(.caption)
                }
            }
            .navigationTitle("Rakuten Analytics tvOS")
        }
        .rviewOnAppear(pageName: "tvos_home") {}
    }
}

private struct SwiftUIPageView: View {
    var body: some View {
        Text("SwiftUI page visit tracking")
            .font(.title2)
            .rviewOnAppear(pageName: "tvos_swiftui_page") {}
    }
}

private struct UIKitPageHostView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitSampleViewController {
        UIKitSampleViewController()
    }

    func updateUIViewController(_ uiViewController: UIKitSampleViewController, context: Context) {}
}

private final class UIKitSampleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let label = UILabel()
        label.text = "UIKit page visit tracking"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
