import SwiftUI
import UIKit

/// A UITextView-backed SwiftUI view that gives inner padding
public struct InnerPaddedTextView: UIViewRepresentable {
    @Binding public var text: String
    public var font: UIFont?
    public var textContainerInset: UIEdgeInsets
    public var isEditable: Bool = true
    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode = .interactive
    public var showsVerticalScrollIndicator: Bool = true
    public var autocapitalizationType: UITextAutocapitalizationType = .none

    // Optional: bind focus if you want to control firstResponder from SwiftUI
    public var isFirstResponder: Binding<Bool>?

    public init(
        text: Binding<String>,
        font: UIFont? = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular),
        textContainerInset: UIEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16),
        isEditable: Bool = true,
        keyboardDismissMode: UIScrollView.KeyboardDismissMode = .interactive,
        showsVerticalScrollIndicator: Bool = true,
        autocapitalizationType: UITextAutocapitalizationType = .none,
        isFirstResponder: Binding<Bool>? = nil
    ) {
        _text = text
        self.font = font
        self.textContainerInset = textContainerInset
        self.isEditable = isEditable
        self.keyboardDismissMode = keyboardDismissMode
        self.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        self.autocapitalizationType = autocapitalizationType
        self.isFirstResponder = isFirstResponder
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.backgroundColor = .clear
        textView.font = font
        textView.text = text
        textView.textContainerInset = textContainerInset
        textView.keyboardDismissMode = keyboardDismissMode
        textView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        textView.autocapitalizationType = autocapitalizationType
        // avoid automatic content inset adjustments interfering
        textView.contentInsetAdjustmentBehavior = .never
        // keep layout flexible
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.alwaysBounceVertical = true
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context _: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.font != font {
            uiView.font = font
        }
        if uiView.textContainerInset != textContainerInset {
            uiView.textContainerInset = textContainerInset
        }
        uiView.isEditable = isEditable
        uiView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        uiView.keyboardDismissMode = keyboardDismissMode
        uiView.autocapitalizationType = autocapitalizationType

        // Manage first responder from binding (optional)
        if let isFirstResponder = isFirstResponder {
            if isFirstResponder.wrappedValue && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFirstResponder.wrappedValue && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    // Coordinator to sync text back to SwiftUI
    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: InnerPaddedTextView
        init(_ parent: InnerPaddedTextView) { self.parent = parent }

        public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        public func textViewDidBeginEditing(_: UITextView) {
            parent.isFirstResponder?.wrappedValue = true
        }

        public func textViewDidEndEditing(_: UITextView) {
            parent.isFirstResponder?.wrappedValue = false
        }
    }
}
