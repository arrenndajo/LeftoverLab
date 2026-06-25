import Testing
import Foundation
@testable import LeftoverLab

// MARK: - Test helpers

private func recipe(
    id: String,
    required: [String] = [],
    optional: [String] = [],
    staples: [String] = [],
    time: Int = 20,
    servedWith: [String]? = nil,
    diet: String? = nil,
    mealTimes: [MealTime]? = nil,
    cuisines: [Cuisine]? = nil
) -> Recipe {
    var ings = required.map { RecipeIngredient(name: $0, isRequired: true, isPantryStaple: false) }
    ings += optional.map { RecipeIngredient(name: $0, isRequired: false, isPantryStaple: false) }
    ings += staples.map { RecipeIngredient(name: $0, isRequired: true, isPantryStaple: true) }
    return Recipe(
        id: id, name: id, chaosName: nil, summary: "", timeMinutes: time,
        difficulty: .easy, dietaryTags: [], cuisines: cuisines, mealTimes: mealTimes,
        nutritious: true, servedWith: servedWith, diet: diet, ingredients: ings, steps: []
    )
}

private func item(_ name: String, _ category: InventoryCategory = .ingredient, expiresInDays days: Int? = nil) -> InventoryItem {
    let date = days.map { Calendar.current.date(byAdding: .day, value: $0, to: .now)! }
    return InventoryItem(name: name, category: category, expirationDate: date)
}

private let matcher = RecipeMatcher()

// MARK: - Classification

@Test func ownsEverything_isCanMakeNow() {
    let r = recipe(id: "khichdi", required: ["rice", "dal"])
    let result = matcher.suggestions(for: [item("rice"), item("dal")], from: [r])
    let s = try! #require(result.first)
    #expect(s.missingRequired.isEmpty)
    #expect(s.buckets.contains(.canMakeNow))
    #expect(!s.buckets.contains(.missingOne))
}

@Test func missingOneRequired_isMissingOne() {
    let r = recipe(id: "khichdi", required: ["rice", "dal"])
    let result = matcher.suggestions(for: [item("rice")], from: [r])
    let s = try! #require(result.first)
    #expect(s.missingRequired == ["dal"])
    #expect(s.buckets.contains(.missingOne))
    #expect(!s.buckets.contains(.canMakeNow))
}

@Test func missingTwoOrMore_isDropped() {
    let r = recipe(id: "big", required: ["a", "b", "c"])
    let result = matcher.suggestions(for: [item("a")], from: [r])
    #expect(result.isEmpty)
}

// MARK: - Pantry staples & normalization

@Test func pantryStaples_neverCountAsMissing() {
    let r = recipe(id: "plain", required: ["rice"], staples: ["salt", "oil", "water"])
    let result = matcher.suggestions(for: [item("rice")], from: [r])
    let s = try! #require(result.first)
    #expect(s.missingRequired.isEmpty)
    #expect(s.buckets.contains(.canMakeNow))
}

@Test func pluralsAndCaseMatch() {
    let r = recipe(id: "fry", required: ["onion", "tomato"])
    let result = matcher.suggestions(for: [item("Onions"), item("Tomatoes")], from: [r])
    let s = try! #require(result.first)
    #expect(s.missingRequired.isEmpty)
}

@Test func synonyms_curdMatchesYogurt_rotiMatchesTortilla() {
    let r = recipe(id: "kadhi", required: ["yogurt", "tortilla"])
    let result = matcher.suggestions(for: [item("curd"), item("roti")], from: [r])
    let s = try! #require(result.first)
    #expect(s.missingRequired.isEmpty)
}

// MARK: - servedWith (the OR-base rule)

@Test func servedWith_missingBase_becomesMissingOne() {
    let r = recipe(id: "dal", required: ["dal"], servedWith: ["rice", "roti"])
    let result = matcher.suggestions(for: [item("dal")], from: [r])
    let s = try! #require(result.first)
    #expect(s.buckets.contains(.missingOne))
    #expect(s.missingRequired.contains("rice or roti"))
}

@Test func servedWith_eitherBaseSatisfies() {
    let r = recipe(id: "dal", required: ["dal"], servedWith: ["rice", "roti"])
    // only roti present (via chapati synonym) should satisfy the base
    let result = matcher.suggestions(for: [item("dal"), item("chapati")], from: [r])
    let s = try! #require(result.first)
    #expect(s.missingRequired.isEmpty)
    #expect(s.buckets.contains(.canMakeNow))
}

// MARK: - Scoring & ordering

@Test func fullyMakeableSmallRecipe_outranksHalfStockedBigRecipe() {
    let small = recipe(id: "small", required: ["a", "b"], time: 20)
    let big = recipe(id: "big", required: ["a", "c"], time: 20) // missing one
    let result = matcher.suggestions(for: [item("a"), item("b")], from: [small, big])
    #expect(result.first?.recipe.id == "small")
}

@Test func quickRecipesSortBeforeSlowOnes() {
    let quick = recipe(id: "quick", required: ["a"], time: 8)
    let slow = recipe(id: "slow", required: ["a"], time: 40)
    let result = matcher.suggestions(for: [item("a")], from: [quick, slow])
    #expect(result.map(\.recipe.id) == ["quick", "slow"])
}

@Test func quickRecipe_getsQuickBucket() {
    let r = recipe(id: "fast", required: ["a"], time: 5)
    let s = try! #require(matcher.suggestions(for: [item("a")], from: [r]).first)
    #expect(s.buckets.contains(.quick))
}

// MARK: - Expiring items

@Test func usesExpiringItem_getsExpiringBucketAndReason() {
    let r = recipe(id: "use-it", required: ["spinach"], time: 15)
    let s = try! #require(matcher.suggestions(for: [item("spinach", expiresInDays: 1)], from: [r]).first)
    #expect(s.usesExpiringItems.contains("spinach"))
    #expect(s.buckets.contains(.usesExpiring))
    #expect(s.reason.contains("expiring"))
}

// MARK: - suggestedIngredients (smart chips)

@Test func suggestedIngredients_rankByUnlockFrequency() {
    let r1 = recipe(id: "r1", required: ["onion", "rice"])
    let r2 = recipe(id: "r2", required: ["onion", "dal"])
    let r3 = recipe(id: "r3", required: ["onion", "paneer"])
    // owns nothing; onion appears in all 3 -> should rank first
    let chips = matcher.suggestedIngredients(for: [], from: [r1, r2, r3])
    #expect(chips.first == "onion")
}

@Test func suggestedIngredients_excludeOwned() {
    let r = recipe(id: "r", required: ["onion", "tomato"])
    let chips = matcher.suggestedIngredients(for: [item("onion")], from: [r])
    #expect(!chips.contains("onion"))
    #expect(chips.contains("tomato"))
}
