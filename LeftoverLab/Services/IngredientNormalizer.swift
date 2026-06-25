import Foundation

enum IngredientNormalizer {
    private static let synonyms: [String: String] = [
        "curd": "yogurt",
        "dahi": "yogurt",
        "roti": "tortilla",
        "chapati": "tortilla",
        "chapatti": "tortilla"
    ]

    static func normalize(_ raw: String) -> String {
        let trimmed = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let singular = singularize(trimmed)
        return synonyms[singular] ?? singular
    }

    static func matches(_ a: String, _ b: String) -> Bool {
        normalize(a) == normalize(b)
    }

    private static func singularize(_ word: String) -> String {
        guard word.count > 3 else { return word }
        if word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("s") && !word.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }
}
