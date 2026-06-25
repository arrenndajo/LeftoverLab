import Foundation

struct Recipe: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let chaosName: String?
    let summary: String
    let timeMinutes: Int
    let difficulty: Difficulty
    let dietaryTags: [DietaryTag]
    let cuisines: [Cuisine]?
    let mealTimes: [MealTime]?
    let nutritious: Bool?
    let servedWith: [String]?
    let diet: String?
    let ingredients: [RecipeIngredient]
    let steps: [String]
}

extension Recipe {
    var requiredIngredients: [RecipeIngredient] {
        ingredients.filter { $0.isRequired && !$0.isPantryStaple }
    }

    var optionalIngredients: [RecipeIngredient] {
        ingredients.filter { !$0.isRequired && !$0.isPantryStaple }
    }

    var cuisineList: [Cuisine] { cuisines ?? [] }
    var mealTimeList: [MealTime] { mealTimes ?? MealTime.allCases }
    var isNutritious: Bool { nutritious ?? true }
    var isQuick: Bool { timeMinutes <= 10 }

    func displayName(chaos: Bool) -> String {
        chaos ? (chaosName ?? name) : name
    }
}
