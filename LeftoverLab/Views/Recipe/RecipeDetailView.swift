import SwiftUI
import SwiftData
import UIKit

struct RecipeDetailView: View {
    let suggestion: MealSuggestion
    let chaos: Bool

    @Query(sort: \Creator.dateAdded) private var creators: [Creator]

    private var recipe: Recipe { suggestion.recipe }
    private var isLeftover: Bool { suggestion.recipe.id.hasPrefix("leftover-") }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.displayName(chaos: chaos)).font(.title2.bold())
                    Text(recipe.summary).font(.body).foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    chip("clock", "\(recipe.timeMinutes) min")
                    chip("chart.bar", recipe.difficulty.label)
                    ForEach(Array(recipe.dietaryTags.prefix(2))) { chip(nil, $0.label) }
                }
                
                if !isLeftover {
                    NavigationLink {
                        CookingModeView(recipe: recipe, chaos: chaos)
                    } label: {
                        Label("Start Cooking", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Brand.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                section("What You Need") {
                    ForEach(recipe.ingredients.filter { !$0.isPantryStaple }, id: \.name) { ing in
                        let owned = isOwned(ing.name)
                        HStack(spacing: 10) {
                            Image(systemName: owned ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(owned ? .green : .secondary)
                            Text(ing.name.capitalized)
                            if !ing.isRequired {
                                Text("optional").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    let staples = recipe.ingredients.filter(\.isPantryStaple).map { $0.name.capitalized }
                    if !staples.isEmpty {
                        Text("Plus pantry staples: \(staples.joined(separator: ", "))")
                            .font(.caption).foregroundStyle(.secondary).padding(.top, 2)
                    }
                }

                section("How to Make It") {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Brand.accent.opacity(0.15)))
                                .foregroundStyle(Brand.accent)
                            Text(step)
                            Spacer()
                        }
                    }
                }

                if !isLeftover {
                    section("Watch It Made") {
                        if creators.isEmpty {
                            Button { openYouTube(recipe.name) } label: {
                                Label("Search YouTube", systemImage: "play.rectangle.fill")
                            }
                            Text("Add your favorite creators in Profile to see their versions here.")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            ForEach(creators) { creator in
                                Button { openYouTube("\(creator.name) \(recipe.name)") } label: {
                                    Label("\(creator.name)'s \(recipe.name)", systemImage: "play.rectangle.fill")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(recipe.displayName(chaos: chaos))
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.accent)
    }

    private func isOwned(_ name: String) -> Bool {
        let n = IngredientNormalizer.normalize(name)
        return suggestion.ownedRequired.contains(n) || suggestion.ownedOptional.contains(n)
    }

    private func openYouTube(_ query: String) {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let web = URL(string: "https://www.youtube.com/results?search_query=\(q)")!
        if let app = URL(string: "youtube://www.youtube.com/results?search_query=\(q)") {
            UIApplication.shared.open(app, options: [:]) { success in
                if !success { UIApplication.shared.open(web) }
            }
        } else {
            UIApplication.shared.open(web)
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
    }

    private func chip(_ system: String?, _ text: String) -> some View {
        HStack(spacing: 4) {
            if let system { Image(systemName: system).font(.caption2) }
            Text(text).font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(.quaternary))
    }
}
