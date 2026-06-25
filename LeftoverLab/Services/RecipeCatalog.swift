import Foundation

final class RecipeCatalog {
    let recipes: [Recipe]

    init(recipes: [Recipe]? = nil) {
        self.recipes = recipes ?? RecipeCatalog.loadBundledRecipes()
    }

    static func loadBundledRecipes() -> [Recipe] {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            assertionFailure("recipes.json not found in app bundle. Check Target Membership.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Recipe].self, from: data)
        } catch {
            assertionFailure("Failed to decode recipes.json: \(error)")
            return []
        }
    }
}
