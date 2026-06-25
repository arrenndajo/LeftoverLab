import SwiftUI
import SwiftData

@main
struct LeftoverLabApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: [InventoryItem.self, Creator.self])
    }
}
