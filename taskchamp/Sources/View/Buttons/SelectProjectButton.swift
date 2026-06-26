import SwiftUI
import taskchampShared

public struct SelectProjectButton: View {
    @Binding var project: String
    var action: () -> Void

    public var body: some View {
        Button {
            action()
        } label: {
            if project.isEmpty {
                Label("Project", systemImage: SFSymbols.folder.rawValue)
                    .labelStyle(.titleAndIcon)
            } else {
                Label {
                    HStack {
                        Text(project)
                            .font(.system(.body, design: .monospaced))
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.accentColor.opacity(0.2))
                            )
                        Spacer()
                    }
                    .onTapGesture {
                        action()
                    }
                } icon: {
                    Image(systemName: SFSymbols.folder.rawValue)
                }
            }
        }
    }
}
