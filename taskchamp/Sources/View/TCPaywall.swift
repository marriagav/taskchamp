import StoreKit
import SwiftUI
import taskchampShared

struct TCPaywall: View {
    @Environment(\.dismiss) var dismiss
    @Environment(StoreKitManager.self) var storeKit: StoreKitManager

    @State var isShowingAlert = false

    @ViewBuilder private var cloudCardSection: some View {
        Section {
            VStack {
                Text("Taskchamp Cloud")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(
                    "If you do not want to go through the hassle of setting up your own Taskchampion server."
                )
                .multilineTextAlignment(.center)
                .font(.subheadline)

                Text("Includes all Taskchamp+ features.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            }
            ProductView(id: StoreKitManager.TCProducts.cloud) {
                Image(systemName: SFSymbols.cloudCheck.rawValue)
                    .foregroundStyle(Color(asset: TaskchampAsset.Assets.accentColor))
            }
            .productViewStyle(.compact)
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack {
                        Text("Taskchamp+")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Lifetime access to all premium features for a one-time payment")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                    }

                    HStack {
                        Label("Custom tags", systemImage: SFSymbols.tag.rawValue)
                        Spacer()
                        Label("CLI filters", systemImage: SFSymbols.terminal.rawValue)
                    }
                    .multilineTextAlignment(.center)
                    .listRowSeparator(.hidden)
                    HStack {
                        Label("Obsidian integration", systemImage: SFSymbols.obsidianNoFill.rawValue)
                        Spacer()
                        Label("And more...", systemImage: SFSymbols.bolt.rawValue)
                    }
                    .multilineTextAlignment(.center)

                    ProductView(id: StoreKitManager.TCProducts.premium) {
                        Image(systemName: SFSymbols.crown.rawValue)
                            .foregroundStyle(Color(asset: TaskchampAsset.Assets.accentColor))
                    }
                    .productViewStyle(.compact)
                }
                // TODO: add cloud card section
                // cloudCardSection
            }
            Section {
                Button("Restore purchases") {
                    Task {
                        do {
                            try await storeKit.restorePurchases()
                            dismiss()
                        } catch {
                            isShowingAlert = true
                        }
                    }
                }
                .buttonStyle(.borderless)
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text(
                        "Something went wrong"
                    ),
                    message: Text(
                        "Please verify your internet connection and try again."
                    ),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onInAppPurchaseCompletion { product, result in
                let result = await storeKit.onInAppPurchaseCompletion(product: product, result: result)
                if result {
                    dismiss()
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
