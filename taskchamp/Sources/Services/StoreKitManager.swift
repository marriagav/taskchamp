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

    var isPremiumUser: Bool {
        return UserDefaultsManager.shared.getValue(forKey: .storeKitPremiumUnlocked) ?? false
    }

    var isCloudUser: Bool {
        return UserDefaultsManager.shared.getValue(forKey: .storeKitCloudSubscriptionActive) ?? false
    }

    func hasPremiumAccess() -> Bool {
        let isPremium: Bool = isPremiumUser
        let isCloud: Bool = isCloudUser
        return isPremium || isCloud
    }

    func restorePurchases() async throws {
        try await StoreKit.AppStore.sync()
        try await updateCustomerProductStatus()
        try await grandfatherExistingUsers()
    }

    func setUserClassForProduct(id: String) {
        switch id {
        case TCProducts.premium:
            if isPremiumUser {
                return
            }
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
        if case let .success(.success(transaction)) = result {
            _ = transaction
            setUserClassForProduct(id: product.id)
            return true
        } else {
            return false
        }
    }

    func onAppInitialization() async throws {
        try await updateCustomerProductStatus()
        try await grandfatherExistingUsers()
    }

    @MainActor
    func updateCustomerProductStatus() async throws {
        // TODO: handle expired cloud subscription
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                setUserClassForProduct(id: transaction.productID)
            } catch {
                throw error
            }
        }
    }

    @MainActor
    func grandfatherExistingUsers() async throws {
        if isPremiumUser {
            return
        }
        // Get the appTransaction.
        let shared = try await AppTransaction.shared
        if case let .verified(appTransaction) = shared {
            // Hard-code the major version number in which the app's business model changed.
            var newBusinessModelMajorVersion = "138"
            #if os(macOS)
            // In macos the originalAppVersion is the version:
            // https://freemiumkit.app/documentation/freemiumkit/migratefrompaid/
            newBusinessModelMajorVersion = "2.0"
            #else
            // In other platforms the originalAppVersion is the build number
            newBusinessModelMajorVersion = "138"
            #endif

            // Get the major version number of the version the customer originally purchased.
            let versionComponents = appTransaction.originalAppVersion.split(separator: ".")
            let originalMajorVersion = versionComponents[0]

            if originalMajorVersion < newBusinessModelMajorVersion {
                // This customer purchased the app before the business model changed.
                // Deliver content that they're entitled to based on their app purchase.
                setUserClassForProduct(id: TCProducts.premium)
            } else {
                // This customer purchased the app after the business model changed.
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
