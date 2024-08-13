import SwiftUI

public struct ContentView: View {
    @State private var isPickerShowing = false
    @State private var taskChampionFileUrl: URL?
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Text("Hello, world!")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPickerShowing.toggle()
                    } label: {
                        Label("Select taskchampion task folder", systemImage: "doc.text.fill")
                    }
                }
            }
            .fileImporter(
                isPresented: $isPickerShowing,
                allowedContentTypes: [.folder]
            ) { result in
                print(result)
                switch result {
                case let .success(url):
                    taskChampionFileUrl = url.appending(path: "taskchampion.sqlite3")
                    print(taskChampionFileUrl ?? "No url")
                case let .failure(error):
                    print(error)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
