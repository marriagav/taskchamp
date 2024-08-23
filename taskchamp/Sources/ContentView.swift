import SwiftUI

public struct ContentView: View {
    @State private var pathStore = PathStore()

    public var body: some View {
        NavigationStack(path: $pathStore.path) {
            TaskListView()
        }
        .environment(pathStore)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
