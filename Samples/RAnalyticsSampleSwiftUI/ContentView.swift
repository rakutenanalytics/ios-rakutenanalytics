import SwiftUI
import RAnalytics

struct ContentView: View {
    @State private var showingSheet = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 40, content: {
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                }

                NavigationLink(destination: SettingsView()) {
                    Text("Settings")
                }

                Button("Sheet") {
                    showingSheet.toggle()

                }.sheet(isPresented: $showingSheet) {
                    SheetView()
                }
            })
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
