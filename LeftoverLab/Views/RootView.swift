import SwiftUI

struct AppRootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            RootView()
        } else {
            OnboardingView()
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            MealSuggestionsView()
                .tabItem { Label("Cook", systemImage: "fork.knife") }
            InventoryView()
                .tabItem { Label("Kitchen", systemImage: "refrigerator") }
            ProfileView()
                .tabItem { Label("Preferences", systemImage: "slider.horizontal.3") }
        }
        .tint(Brand.accent)
    }
}
