import SwiftUI

struct TCInstructionsView<Content: View>: View {
    private let instructions: [String]
    private let summary: String
    let content: Content

    init(summary: String, instructions: [String], @ViewBuilder content: () -> Content) {
        self.instructions = instructions
        self.summary = summary
        self.content = content()
    }

    var instructionsSection: some View {
        Section("Instructions") {
            ForEach(instructions, id: \.self) { instruction in
                Text(.init(instruction))
            }
        }
    }

    var body: some View {
        Form {
            Section {
                Text(.init(summary))
                    .foregroundStyle(.secondary)
            }
            if !instructions.isEmpty {
                instructionsSection
            }
            content
        }
    }
}
