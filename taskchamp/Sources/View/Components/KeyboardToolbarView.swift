import SwiftUI
import taskchampShared

protocol UseKeyboardToolbar {
    func calculateNextField()
    func calculatePreviousField()
    func onDismissKeyboard()
}

public struct KeyboardToolbarView<Content: View>: View {
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onDismiss: () -> Void
    var skipNextAndPrevious: () -> Bool

    private let content: Content

    // MARK: - Init with content

    public init(
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        skipNextAndPrevious: @escaping () -> Bool = { false },
        @ViewBuilder content: () -> Content
    ) {
        self.skipNextAndPrevious = skipNextAndPrevious
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onDismiss = onDismiss
        self.content = content()
    }

    // MARK: - Init without content (defaults to EmptyView)

    public init(
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        skipNextAndPrevious: @escaping () -> Bool = { false },
    ) where Content == EmptyView {
        self.skipNextAndPrevious = skipNextAndPrevious
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onDismiss = onDismiss
        content = EmptyView()
    }

    // MARK: - Body

    @ViewBuilder
    private func bodyWithoutNextAndPrevious() -> some View {
        HStack {
            Button(action: onPrevious) {
                Label("Previous", systemImage: SFSymbols.chevronUp.rawValue)
            }.hidden()
            Spacer()
            content
            Spacer()
            Button(action: onDismiss) {
                Label("Dismiss keyboard", systemImage: SFSymbols.checkmark.rawValue)
            }
        }
    }

    @ViewBuilder
    private func bodyWithoutNextAndPreviousWithBody() -> some View {
        HStack {
            Button("") {}
                .hidden()
            Spacer()
            content
            Spacer()
            Button(action: onDismiss) {
                Label("Dismiss keyboard", systemImage: SFSymbols.checkmark.rawValue)
            }
        }
    }

    @ViewBuilder
    private func bodyWithNextAndPrevious() -> some View {
        HStack {
            Button(action: onPrevious) {
                Label("Previous", systemImage: SFSymbols.chevronUp.rawValue)
            }
            Button(action: onNext) {
                Label("Next", systemImage: SFSymbols.chevronDown.rawValue)
            }
            Spacer()
            content
            Spacer()
            Button(action: onDismiss) {
                Label("Dismiss keyboard", systemImage: SFSymbols.checkmark.rawValue)
            }
        }
    }

    public var body: some View {
        if skipNextAndPrevious() {
            if content is EmptyView {
                bodyWithoutNextAndPrevious()
            } else {
                bodyWithoutNextAndPreviousWithBody()
            }
        } else {
            bodyWithNextAndPrevious()
        }
    }
}
