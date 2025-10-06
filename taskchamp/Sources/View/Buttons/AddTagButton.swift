import SwiftUI
import taskchampShared

public struct AddTagButton: View {
    @Binding var tags: [TCTag]
    var action: () -> Void

    var uniqueTags: [TCTag] {
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
                        HStack {
                            ForEach(uniqueTags, id: \.self) { tag in
                                Text(tag.name)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.accentColor.opacity(0.2))
                                    )
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
