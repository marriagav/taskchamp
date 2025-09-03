import SwiftUI
import taskchampShared

struct TCSyncServiceButtonSectionView: View {
    var buttonTitle: String
    var action: () -> Void
    var isDisabled: Bool = false
    var systemImage: String = SFSymbols.cloud.rawValue

    var body: some View {
        Section {
            Button(action: {
                action()
            }, label: {
                Label(
                    isDisabled ? "Saving..." : buttonTitle,
                    systemImage: systemImage
                )
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            })
            .buttonStyle(.borderedProminent)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .disabled(isDisabled)
        }
    }
}
