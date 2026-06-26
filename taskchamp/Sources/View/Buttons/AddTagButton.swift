import SwiftUI
import taskchampShared

public struct AddTagButton: View {
    @Binding var tags: [TCTag]
    var action: () -> Void

    private var uniqueTags: [TCTag] {
        var seen = Set<String>()
        return tags.filter { tag in
            if seen.contains(tag.name) {
                return false
            } else {
                seen.insert(tag.name)
                return true
            }
        }
    }

    private var userTags: [TCTag] {
        uniqueTags.filter { !$0.isSynthetic() }
    }

    private var syntheticTags: [TCTag] {
        uniqueTags.filter { $0.isSynthetic() }
    }

    @ViewBuilder
    private func tagChip(_ tag: TCTag, synthetic: Bool) -> some View {
        Text(tag.name)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(synthetic ? .secondary : .primary)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill((synthetic ? Color.secondary : Color.accentColor).opacity(0.2))
            )
    }

    public var body: some View {
        Button {
            action()
        } label: {
            if tags.isEmpty {
                Label("Tags", systemImage: SFSymbols.tag.rawValue)
                    .labelStyle(.titleAndIcon)
            } else {
                Label {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if !userTags.isEmpty {
                                HStack {
                                    ForEach(userTags, id: \.self) { tag in
                                        tagChip(tag, synthetic: false)
                                    }
                                }
                            }
                            if !userTags.isEmpty && !syntheticTags.isEmpty {
                                Divider()
                                    .frame(height: 20)
                            }
                            if !syntheticTags.isEmpty {
                                HStack {
                                    ForEach(syntheticTags, id: \.self) { tag in
                                        tagChip(tag, synthetic: true)
                                    }
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        action()
                    }
                } icon: {
                    Image(systemName: SFSymbols.tag.rawValue)
                }
            }
        }
    }
}
