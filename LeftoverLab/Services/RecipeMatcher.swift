import Foundation

struct RecipeMatcher {
    let expiringSoonDays: Int

    init(expiringSoonDays: Int = 3) {
        self.expiringSoonDays = expiringSoonDays
    }

    func suggestions(for items: [InventoryItem], from recipes: [Recipe], chaosMode: Bool = false) -> [MealSuggestion] {
        let owned = normalizedSet(items)
        let expiring = normalizedSet(items.filter(\.isExpiringSoon))
        let leftovers = normalizedSet(items.filter { $0.category == .leftover })
        let readyToCook = normalizedSet(items.filter { $0.category == .readyToCook })

        return recipes
            .compactMap { evaluate($0, owned: owned, expiring: expiring,
                                   leftovers: leftovers, readyToCook: readyToCook, chaos: chaosMode) }
            .sorted {
                $0.recipe.timeMinutes != $1.recipe.timeMinutes
                    ? $0.recipe.timeMinutes < $1.recipe.timeMinutes
                    : $0.score > $1.score
            }
    }

    func suggestedIngredients(for items: [InventoryItem], from recipes: [Recipe], limit: Int = 6) -> [String] {
        let owned = normalizedSet(items)
        var counts: [String: Int] = [:]
        for recipe in recipes {
            for ingredient in recipe.requiredIngredients {
                let name = IngredientNormalizer.normalize(ingredient.name)
                if !owned.contains(name) {
                    counts[name, default: 0] += 1
                }
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    private func normalizedSet(_ items: [InventoryItem]) -> Set<String> {
        Set(items.map { IngredientNormalizer.normalize($0.name) })
    }

    private func evaluate(_ recipe: Recipe, owned: Set<String>, expiring: Set<String>,
                          leftovers: Set<String>, readyToCook: Set<String>, chaos: Bool) -> MealSuggestion? {
        let required = recipe.requiredIngredients.map { IngredientNormalizer.normalize($0.name) }
        let optional = recipe.optionalIngredients.map { IngredientNormalizer.normalize($0.name) }

        let ownedRequired = required.filter { owned.contains($0) }
        var missingRequired = required.filter { !owned.contains($0) }
        let ownedOptional = optional.filter { owned.contains($0) }

        // "Served with" base — dal/sabzi need at least one of e.g. rice or roti
        let baseOptions = (recipe.servedWith ?? []).map { IngredientNormalizer.normalize($0) }
        let hasBase = baseOptions.isEmpty || baseOptions.contains { owned.contains($0) }
        if !hasBase {
            missingRequired.append((recipe.servedWith ?? []).joined(separator: " or "))
        }

        guard missingRequired.count <= 1 else { return nil }

        let ownedAll = ownedRequired + ownedOptional
        let usedExpiring = ownedAll.filter { expiring.contains($0) }
        let usesLeftover = ownedAll.contains { leftovers.contains($0) }
        let usesReady = ownedAll.contains { readyToCook.contains($0) }

        let coverage = Double(ownedRequired.count) / Double(max(required.count, 1))

        var score = coverage * 60
        score += Double(ownedOptional.count) * 3
        score += Double(usedExpiring.count) * 8
        score += recipe.isQuick ? 5 : 0
        score += usesLeftover ? 4 : 0
        score += usesReady ? 2 : 0
        score -= Double(missingRequired.count) * 12
        score -= recipe.timeMinutes >= 35 ? 4 : 0

        var buckets: Set<SuggestionBucket> = missingRequired.isEmpty ? [.canMakeNow] : [.missingOne]
        if missingRequired.isEmpty && !usedExpiring.isEmpty { buckets.insert(.usesExpiring) }
        if recipe.isQuick { buckets.insert(.quick) }
        if chaos { buckets.insert(.chaos) }

        return MealSuggestion(
            recipe: recipe,
            ownedRequired: ownedRequired,
            missingRequired: missingRequired,
            ownedOptional: ownedOptional,
            usesExpiringItems: usedExpiring,
            score: score,
            buckets: buckets,
            reason: makeReason(recipe, missing: missingRequired, expiring: usedExpiring)
        )
    }

    private func makeReason(_ recipe: Recipe, missing: [String], expiring: [String]) -> String {
        if let item = expiring.first { return "Uses your \(item), expiring soon." }
        if let item = missing.first { return "Just need \(item) to make this." }
        if recipe.isQuick { return "You have everything — ready in \(recipe.timeMinutes) min." }
        return "You have everything you need."
    }
}
