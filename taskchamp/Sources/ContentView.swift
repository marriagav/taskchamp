import SwiftUI
import taskchampShared

public struct ContentView: View {
    @State private var pathStore = PathStore()
    @State private var isShowingAlert = false
    @State private var selectedFilter: TCFilter = .defaultFilter

    private func getSelectedFilter() -> TCFilter {
        do {
            if let data = UserDefaults.standard.data(forKey: "selectedFilter") {
                let res = try JSONDecoder().decode(TCFilter.self, from: data)
                return res
            } else {
                return .defaultFilter
            }
        } catch {
            return .defaultFilter
        }
    }

    public var body: some View {
        NavigationStack(path: $pathStore.path) {
            TaskListView(isShowingICloudAlert: $isShowingAlert, selectedFilter: $selectedFilter)
        }
        .onAppear {
            // TODO: WORKING HERE :D
            print("MURSH8:", printAnExample())
            selectedFilter = getSelectedFilter()
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
