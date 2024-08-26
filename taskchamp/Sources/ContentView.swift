import SwiftUI
import taskchampShared

public struct ContentView: View {
    @State private var pathStore = PathStore()
    @State private var isShowingAlert = false

    public var body: some View {
        NavigationStack(path: $pathStore.path) {
            TaskListView(isShowingICloudAlert: $isShowingAlert)
        }
        .onAppear {
            if FileService.shared.isICloudAvailable() {
                print("iCloud Available")
            } else {
                print("iCloud Unavailable")
                isShowingAlert = true
            }
        }
        .environment(pathStore)
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("iCloud Required"),
                message: Text(
                    "In order to use Taskchamp, you require to have an iCloud account and iCloud Drive enabled"
                ),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
