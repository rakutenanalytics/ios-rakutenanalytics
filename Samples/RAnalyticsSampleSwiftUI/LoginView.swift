import SwiftUI
import RAnalytics

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Login page")
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .rviewOnAppear(pageName: "Login")
    }
}
