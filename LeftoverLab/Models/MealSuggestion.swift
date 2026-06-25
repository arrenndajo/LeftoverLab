import Foundation

enum SuggestionBucket: String, CaseIterable, Identifiable {
    case canMakeNow, missingOne, quick, usesExpiring, chaos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .canMakeNow: "Can Make Now"
        case .missingOne: "Missing One Ingredient"
        case .quick: "Quick Meals"
        case .usesExpiring: "Use Ingredients Expiring Soon"
        case .chaos: "Chaos Mode"
        }
    }

    var systemImage: String {
        switch self {
        case .canMakeNow: "checkmark.circle.fill"
        case .missingOne: "cart.badge.plus"
        case .quick: "bolt.fill"
        case .usesExpiring: "clock.badge.exclamationmark"
        case .chaos: "dice.fill"
        }
    }
}

struct MealSuggestion: Identifiable, Hashable {
    let recipe: Recipe
    let ownedRequired: [String]
    let missingRequired: [String]
    let ownedOptional: [String]
    let usesExpiringItems: [String]
    let score: Double
    let buckets: Set<SuggestionBucket>
    let reason: String

    var id: String { recipe.id }
}
