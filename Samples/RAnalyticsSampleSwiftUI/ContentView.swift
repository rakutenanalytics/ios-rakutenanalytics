import SwiftUI
import RAnalytics

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                }.padding(40)

                NavigationLink(destination: SettingsView()) {
                    Text("Settings")
                }
            }
            .navigationTitle("RAnalyticsSampleSwiftUI")
            .navigationBarTitleDisplayMode(.inline)
            .rviewOnAppear(pageName: "Home")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
