import StoreKit

@Observable
class StoreKitManager {
    enum TCProducts {
        static let premium = "premium.com.mav.taskchamp"
        static let cloud = "cloud.com.mav.taskchamp"
    }

    var groupId = "5E2EC388"

    func restorePurchases() async throws {
        try await StoreKit.AppStore.sync()
    }
}
