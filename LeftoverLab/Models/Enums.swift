import Foundation

enum InventoryCategory: String, Codable, CaseIterable, Identifiable {
    case ingredient, leftover, readyToCook
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ingredient: "Ingredient"
        case .leftover: "Leftover"
        case .readyToCook: "Ready to Cook"
        }
    }
}

enum StorageLocation: String, Codable, CaseIterable, Identifiable {
    case fridge, freezer, pantry, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .fridge: "refrigerator"
        case .freezer: "snowflake"
        case .pantry: "cabinet"
        case .other: "shippingbox"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy, medium, hard
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum DietaryTag: String, Codable, CaseIterable, Identifiable {
    case vegetarian, vegan, glutenFree, dairyFree, protein, carb, spicy, quick, frozen
    var id: String { rawValue }
    var label: String {
        switch self {
        case .glutenFree: "Gluten-Free"
        case .dairyFree: "Dairy-Free"
        default: rawValue.capitalized
        }
    }
}
