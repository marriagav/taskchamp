import SwiftUI
import taskchampShared

protocol UseKeyboardToolbar {
    func calculateNextField()
    func calculatePreviousField()
    func onDismissKeyboard()
}

public struct KeyboardToolbarView: View {
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onDismiss: () -> Void

    public var body: some View {
        HStack {
            Button {
                onPrevious()
            } label: {
                Label("Previous", systemImage: SFSymbols.chevronUp.rawValue)
            }
            Button {
                onNext()
            } label: {
                Label("Next", systemImage: SFSymbols.chevronDown.rawValue)
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Label("Dismiss keyboard", systemImage: SFSymbols.checkmark.rawValue)
            }
        }
    }
}
