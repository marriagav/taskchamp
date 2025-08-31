import SwiftUI

struct TCSpinnerView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(2)
        }
    }
}
