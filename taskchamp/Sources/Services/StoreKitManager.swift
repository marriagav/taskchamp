import StoreKit
import taskchampShared

@Observable
class StoreKitManager {
    enum TCProducts {
        static let premium = "premium.com.mav.taskchamp"
        static let cloud = "cloud.com.mav.taskchamp"
    }

    // var groupId = "5E2EC388" // TODO: update

    enum TCUserStatus {
        case free
        case premium
        case cloud
    }

    func hasPremiumAccess() -> Bool {
        let isPremium: Bool = UserDefaultsManager.shared.getValue(forKey: .storeKitPremiumUnlocked) ?? false
        let isCloud: Bool = UserDefaultsManager.shared.getValue(forKey: .storeKitCloudSubscriptionActive) ?? false
        return isPremium || isCloud
    }

    func restorePurchases() async throws {
        try await StoreKit.AppStore.sync()
        try await updateCustomerProductStatus()
    }

    func setUserClassForProduct(id: String) {
        switch id {
        case TCProducts.premium:
            UserDefaultsManager.shared.set(value: true, forKey: .storeKitPremiumUnlocked)
        case TCProducts.cloud:
            UserDefaultsManager.shared.set(value: true, forKey: .storeKitCloudSubscriptionActive)
        default:
            return
        }
    }

    func onInAppPurchaseCompletion(
        product: Product, result: Result<Product.PurchaseResult, any Error>
    ) async -> Bool {
        guard case let .success(.success(transaction)) = result else {
            return false
        }
        setUserClassForProduct(id: product.id)
        return true
    }

    @MainActor
    func updateCustomerProductStatus() async throws {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                setUserClassForProduct(id: transaction.productID)
            } catch {
                throw error
            }
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TCError.genericError("Transaction could not be verified")
        case let .verified(safe):
            return safe
        }
    }
}
