import Foundation

struct RecipeIngredient: Codable, Hashable, Identifiable {
    let name: String
    let isRequired: Bool
    let isPantryStaple: Bool

    var id: String { name.lowercased() }

    init(name: String, isRequired: Bool = true, isPantryStaple: Bool = false) {
        self.name = name
        self.isRequired = isRequired
        self.isPantryStaple = isPantryStaple
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        isRequired = try c.decodeIfPresent(Bool.self, forKey: .isRequired) ?? true
        isPantryStaple = try c.decodeIfPresent(Bool.self, forKey: .isPantryStaple) ?? false
    }
}
