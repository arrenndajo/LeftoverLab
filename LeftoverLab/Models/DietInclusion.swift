import Foundation

enum DietInclusion: String, Codable, CaseIterable, Identifiable, Hashable {
    case egg, chicken, otherMeat

    var id: String { rawValue }

    var label: String {
        switch self {
        case .egg: "Eggs"
        case .chicken: "Chicken"
        case .otherMeat: "Other meat & seafood"
        }
    }

    static func decode(_ raw: String) -> Set<DietInclusion> {
        Set(raw.split(separator: ",").compactMap { DietInclusion(rawValue: String($0)) })
    }
    static func encode(_ set: Set<DietInclusion>) -> String {
        set.map(\.rawValue).sorted().joined(separator: ",")
    }

    static func required(for recipe: Recipe) -> Set<DietInclusion> {
        if let diet = recipe.diet?.lowercased() {
            switch diet {
            case "egg": return [.egg]
            case "chicken": return [.chicken]
            case "othermeat", "meat", "nonveg": return [.otherMeat]
            default: return []   // "veg"
            }
        }
        // Fallback for recipes without an explicit diet field
        var result: Set<DietInclusion> = []
        let others = ["mutton", "goat", "lamb", "beef", "pork", "fish", "prawn", "shrimp", "seafood", "crab", "bacon", "ham"]
        for ingredient in recipe.ingredients {
            let name = ingredient.name.lowercased()
            if name.contains("chicken") { result.insert(.chicken) }
            else if others.contains(where: name.contains) { result.insert(.otherMeat) }
            if name.contains("egg") { result.insert(.egg) }
        }
        return result
    }
}
