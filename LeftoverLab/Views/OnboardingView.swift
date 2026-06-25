import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("selectedCuisines") private var rawCuisines = ""

    private var selection: Binding<Set<Cuisine>> {
        Binding(get: { Cuisine.decode(rawCuisines) }, set: { rawCuisines = Cuisine.encode($0) })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Brand.accent)
                        Text("Welcome to LeftoverLab").font(.title2.bold())
                        Text("Pick the cuisines you cook most and we'll tailor suggestions to your taste. You can change this anytime in Profile.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                Section("Choose your cuisines") {
                    CuisineSelector(selected: selection)
                }
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button { hasOnboarded = true } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Brand.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
        }
        .tint(Brand.accent)
    }
}
