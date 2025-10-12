import SwiftUI

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 4) {
            configuration.icon
                .foregroundStyle(Color(asset: TaskchampAsset.Assets.accentColor))
                .font(.title2)
            configuration.title
                .font(.headline)
        }
        .padding(4)
    }
}
