import SwiftUI
import SwiftData

struct MealSuggestionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \InventoryItem.dateAdded, order: .reverse) private var items: [InventoryItem]
    @State private var catalog = RecipeCatalog()
    @State private var selectedMealTime: MealTime = .current()
    @State private var isRefreshing = false
    @State private var refreshTrigger = 0
    @AppStorage("chaosMode") private var chaosMode = false
    @AppStorage("selectedCuisines") private var rawCuisines = ""
    @AppStorage("dietInclusions") private var rawDiet = ""
    @AppStorage("preferNutritious") private var preferNutritious = true

    private let displayBuckets: [SuggestionBucket] = [.quick, .canMakeNow, .usesExpiring, .missingOne]

    private var filteredRecipes: [Recipe] {
        let selectedCuisines = Cuisine.decode(rawCuisines)
        let diet = DietInclusion.decode(rawDiet)
        return catalog.recipes.filter { recipe in
            let cuisineOK = selectedCuisines.isEmpty
                || recipe.cuisineList.isEmpty
                || !Set(recipe.cuisineList).isDisjoint(with: selectedCuisines)
            let mealOK = recipe.mealTimeList.contains(selectedMealTime)
            let dietOK = DietInclusion.required(for: recipe).isSubset(of: diet)
            let nutritionOK = !preferNutritious || recipe.isNutritious
            return cuisineOK && mealOK && dietOK && nutritionOK
        }
    }

    // Leftovers skip cuisine/diet filters (it's your food) but DO respect mealtime.
    private var leftoverRecipes: [Recipe] {
        LeftoverSuggester.recipes(from: items)
            .filter { $0.mealTimeList.contains(selectedMealTime) }
    }

    private var ranked: [MealSuggestion] {
        RecipeMatcher().suggestions(for: items, from: filteredRecipes + leftoverRecipes, chaosMode: chaosMode)
    }

    private var suggestedIngredients: [String] {
        RecipeMatcher().suggestedIngredients(for: items, from: filteredRecipes)
    }

    private func bucketPlacement(_ list: [MealSuggestion]) -> [String: SuggestionBucket] {
        var result: [String: SuggestionBucket] = [:]
        for suggestion in list {
            if let bucket = displayBuckets.first(where: { suggestion.buckets.contains($0) }) {
                result[suggestion.id] = bucket
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing in your kitchen yet",
                        systemImage: "sparkles",
                        description: Text("Add a few items in the Kitchen tab and we'll suggest meals you can make.")
                    )
                } else {
                    let all = ranked
                    let leftovers = all.filter { $0.id.hasPrefix("leftover-") }
                    let cooked = all.filter { !$0.id.hasPrefix("leftover-") }
                    let placement = bucketPlacement(cooked)

                    List {
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(MealTime.allCases) { meal in
                                        let isSelected = meal == selectedMealTime
                                        Button { selectedMealTime = meal } label: {
                                            Label(meal.label, systemImage: meal.systemImage)
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 18)
                                                .padding(.vertical, 11)
                                                .background(Capsule().fill(isSelected ? Brand.accent : Color(.secondarySystemFill)))
                                                .foregroundStyle(isSelected ? .white : .primary)
                                                .shadow(color: isSelected ? Brand.accent.opacity(0.30) : .clear, radius: 6, y: 3)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(meal.label)
                                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }

                        if !leftovers.isEmpty {
                            Section {
                                ForEach(leftovers) { suggestion in
                                    NavigationLink {
                                        RecipeDetailView(suggestion: suggestion, chaos: chaosMode)
                                    } label: {
                                        SuggestionCard(suggestion: suggestion, chaos: chaosMode)
                                    }
                                    .listRowBackground(suggestion.missingRequired.isEmpty ? Color.green.opacity(0.12) : nil)
                                }
                            } header: {
                                Label("Use Your Leftovers", systemImage: "takeoutbag.and.cup.and.straw.fill")
                                    .font(.headline).foregroundStyle(.primary).textCase(nil)
                            }
                        }

                        if !suggestedIngredients.isEmpty {
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(suggestedIngredients, id: \.self) { name in
                                            Button { addIngredient(name) } label: {
                                                Label(name.capitalized, systemImage: "plus")
                                                    .font(.subheadline.weight(.medium))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(Capsule().fill(Brand.accent.opacity(0.15)))
                                                    .foregroundStyle(Brand.accent)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("Add \(name)")
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } header: {
                                Text("Do you have any of these?")
                                    .font(.headline).foregroundStyle(.primary).textCase(nil)
                            }
                        }

                        if cooked.isEmpty && leftovers.isEmpty {
                            Section {
                                Text("Nothing matches for \(selectedMealTime.label.lowercased()) yet. Tap an ingredient above, switch mealtime, or widen your cuisines in Preferences.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(displayBuckets) { bucket in
                                let matches = cooked.filter { placement[$0.id] == bucket }
                                if !matches.isEmpty {
                                    Section {
                                        ForEach(matches) { suggestion in
                                            NavigationLink {
                                                RecipeDetailView(suggestion: suggestion, chaos: chaosMode)
                                            } label: {
                                                SuggestionCard(suggestion: suggestion, chaos: chaosMode)
                                            }
                                            .listRowBackground(suggestion.missingRequired.isEmpty ? Color.green.opacity(0.12) : nil)
                                        }
                                    } header: {
                                        Label(bucket.title, systemImage: bucket.systemImage)
                                            .font(.headline).foregroundStyle(.primary).textCase(nil)
                                    }
                                }
                            }
                        }
                    }
                    .id(refreshTrigger)
                }
            }
            .overlay {
                if isRefreshing {
                    ProgressView("Refreshing…")
                        .controlSize(.large)
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isRefreshing)
            .navigationTitle("What to Cook")
            .sensoryFeedback(.impact, trigger: refreshTrigger)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { refresh() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                    .accessibilityLabel("Refresh recipes")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { chaosMode.toggle() } label: {
                        Text("aA")
                            .font(.headline)
                            .foregroundStyle(chaosMode ? Brand.accent : .secondary)
                    }
                    .accessibilityLabel(chaosMode ? "Show original recipe names" : "Show English recipe names")
                }
            }
        }
    }

    private func addIngredient(_ name: String) {
        context.insert(InventoryItem(name: name.capitalized, category: .ingredient))
    }

    private func refresh() {
        isRefreshing = true
        refreshTrigger += 1
        catalog = RecipeCatalog()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isRefreshing = false
        }
    }
}

private struct SuggestionCard: View {
    let suggestion: MealSuggestion
    let chaos: Bool

    private var recipe: Recipe { suggestion.recipe }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(recipe.displayName(chaos: chaos))
                    .font(.headline)
                if suggestion.missingRequired.isEmpty {
                    Label("Ready", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
                Spacer()
                Label("\(recipe.timeMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(suggestion.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(suggestion.missingRequired, id: \.self) { name in
                    chip("Need \(name)", system: "cart", tint: Brand.accent)
                }
                ForEach(Array(recipe.dietaryTags.prefix(2)), id: \.self) { tag in
                    chip(tag.label, tint: .gray)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func chip(_ text: String, system: String? = nil, tint: Color) -> some View {
        HStack(spacing: 3) {
            if let system { Image(systemName: system).font(.caption2) }
            Text(text).font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundStyle(tint)
        .background(Capsule().fill(tint.opacity(0.15)))
    }
}
