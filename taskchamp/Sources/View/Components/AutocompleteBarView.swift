import SwiftUI
import taskchampShared

public struct AutocompleteBarView: View {
    @Binding var text: String
    var surface: NLPService.Surface

    var suggestions: [String] {
        NLPService.shared.autoCompleteSuggestions(for: text, surface: surface)
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        text = NLPService.shared.getAutoCompletedString(for: text, suggestion: suggestion)
                        // swiftlint:disable:next multiple_closures_with_trailing_closure
                    }) {
                        Text(suggestion)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.accentColor.opacity(0.2))
                            )
                    }
                }
            }
        }
    }
}
