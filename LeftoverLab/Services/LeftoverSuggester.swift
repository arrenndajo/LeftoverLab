import Foundation

enum LeftoverSuggester {
    private enum Base { case rice, roti }

    static func recipes(from items: [InventoryItem]) -> [Recipe] {
        let leftovers = items.filter { $0.category == .leftover }

        return leftovers.map { leftover in
            let lower = leftover.name.lowercased()
            let needed = neededBases(for: lower)

            let others = items.filter { $0 !== leftover }

            // What can pair with this leftover, looking at the rest of the kitchen.
            let riceItem = others.first { $0.name.lowercased().contains("rice") }
            let rotiItem = others.first { item in
                let n = item.name.lowercased()
                return ["roti", "paratha", "chapati", "tortilla", "naan", "bread"].contains { n.contains($0) }
            }
            // A curry/dal/sabzi the user has, to pair with a plain-carb leftover like rice.
            let curryItem = others.first { isCurry($0.name.lowercased()) }

            var servedWith: [String]? = nil
            let summary: String
            let baseStep: String

            switch needed {
            case .complete:
                summary = "Already a full meal — just reheat and eat."
                baseStep = "That's it, it's complete on its own."

            case .carbBase:
                // The leftover IS the base (plain rice). Pair it with a dal/curry.
                if let curry = curryItem {
                    let c = curry.name.lowercased()
                    summary = "Reheat and serve with your \(c)."
                    baseStep = "Warm your \(c) and serve it over the \(lower)."
                } else {
                    servedWith = ["dal", "curry"]
                    summary = "Reheat and pair with a dal or curry to make it a meal."
                    baseStep = "Serve it with a dal, sabzi, or curry."
                }

            case .needsBase(let bases):
                if bases.contains(.roti), let roti = rotiItem {
                    let b = roti.name.lowercased()
                    summary = "Ready to eat — pair it with your \(b), no cooking needed."
                    baseStep = "Warm your \(b) (already made) and serve it with the \(lower)."
                } else if bases.contains(.rice), let rice = riceItem,
                          rice.category == .leftover || rice.category == .readyToCook {
                    let b = rice.name.lowercased()
                    summary = "Ready to eat — serve it with your \(b)."
                    baseStep = "Reheat your \(b) and serve it with the \(lower)."
                } else if bases.contains(.rice), riceItem?.category == .ingredient {
                    summary = "Reheat the \(lower) and cook a little rice to go with it."
                    baseStep = "Cook a small pot of rice (about 15 min) to serve alongside the \(lower)."
                } else {
                    servedWith = baseNames(bases)
                    let names = baseNames(bases).joined(separator: " or ")
                    summary = "Reheat and eat — add \(names) to round it out."
                    baseStep = "Grab \(names) to go with it."
                }
            }

            return Recipe(
                id: "leftover-\(lower)",
                name: leftover.name,
                chaosName: nil,
                summary: summary,
                timeMinutes: 5,
                difficulty: .easy,
                dietaryTags: [],
                cuisines: nil,
                mealTimes: [.lunch, .dinner],
                nutritious: true,
                servedWith: servedWith,
                diet: nil,
                ingredients: [RecipeIngredient(name: leftover.name, isRequired: true, isPantryStaple: false)],
                steps: [
                    "Take out your \(lower) and reheat until hot all the way through.",
                    baseStep,
                    "Plate it up and enjoy."
                ]
            )
        }
    }

    private enum Need {
        case complete            // composed dish, eat alone (fried rice, biryani, pulao)
        case carbBase            // plain carb that needs a dal/curry (plain rice)
        case needsBase(Set<Base>) // a dish that needs rice and/or roti
    }

    private static func neededBases(for name: String) -> Need {
        // Composed one-dish meals — eat as-is.
        let complete = ["fried rice", "pulao", "pulav", "biryani", "khichdi", "pasta",
                        "noodle", "poha", "upma", "pizza", "sandwich", "idli", "dosa",
                        "paratha", "thepla", "frankie", "roll", "wrap"]
        if complete.contains(where: name.contains) { return .complete }

        // Plain rice on its own is a base — pair it with a dal/curry.
        if name.contains("rice") || name.contains("chawal") { return .carbBase }

        // Breads as leftovers: complete enough to eat with anything, treat as complete.
        if ["roti", "chapati", "naan", "bhakri"].contains(where: name.contains) { return .complete }

        // Eaten with both rice and roti.
        let both = ["sabji", "sabzi", "shaak", "dal fry", "dal tadka", "dal makhani",
                    "dal makhni", "green moong", "moong", "rajma", "chole", "chhole",
                    "chana", "paneer", "aloo", "gobi", "bhindi", "baingan", "matar",
                    "mix veg", "kofta", "bhaji"]
        if both.contains(where: name.contains) { return .needsBase([.rice, .roti]) }

        // Default (plain dal, kadhi, sambar, rasam, curry) — rice.
        return .needsBase([.rice])
    }

    private static func isCurry(_ name: String) -> Bool {
        let curry = ["dal", "green moong", "moong", "rajma", "chole", "chhole", "chana",
                     "sabji", "sabzi", "shaak", "kadhi", "curry", "sambar", "rasam",
                     "paneer", "kofta", "aloo", "matar"]
        return curry.contains { name.contains($0) }
    }

    private static func baseNames(_ bases: Set<Base>) -> [String] {
        var names: [String] = []
        if bases.contains(.rice) { names.append("rice") }
        if bases.contains(.roti) { names.append("roti") }
        return names
    }
}
