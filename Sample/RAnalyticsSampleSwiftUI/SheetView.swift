import SwiftUI

struct SheetView: View {
    var body: some View {
        VStack {
            Text("Sheet page")
        }
        .navigationTitle("Sheet")
        .navigationBarTitleDisplayMode(.inline)
        .rviewOnAppear(pageName: "Sheet")
    }
}
