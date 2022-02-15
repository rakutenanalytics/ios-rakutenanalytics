import SwiftUI
import RAnalytics

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings page")
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .rviewOnAppear(pageName: "Settings")
    }
}
