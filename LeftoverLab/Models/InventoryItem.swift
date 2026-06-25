import Foundation
import SwiftData

@Model
final class InventoryItem {
    var name: String
    var categoryRaw: String
    var quantity: String
    var locationRaw: String
    var expirationDate: Date?
    var tagsRaw: [String]
    var dateAdded: Date

    init(
        name: String,
        category: InventoryCategory,
        quantity: String = "1",
        location: StorageLocation = .fridge,
        expirationDate: Date? = nil,
        tags: [DietaryTag] = []
    ) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.quantity = quantity
        self.locationRaw = location.rawValue
        self.expirationDate = expirationDate
        self.tagsRaw = tags.map(\.rawValue)
        self.dateAdded = Date()
    }
}

extension InventoryItem {
    var category: InventoryCategory {
        get { InventoryCategory(rawValue: categoryRaw) ?? .ingredient }
        set { categoryRaw = newValue.rawValue }
    }

    var location: StorageLocation {
        get { StorageLocation(rawValue: locationRaw) ?? .fridge }
        set { locationRaw = newValue.rawValue }
    }

    var tags: [DietaryTag] {
        get { tagsRaw.compactMap(DietaryTag.init(rawValue:)) }
        set { tagsRaw = newValue.map(\.rawValue) }
    }

    var normalizedName: String {
        name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isExpiringSoon: Bool {
        guard let expirationDate else { return false }
        let threshold = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return expirationDate <= threshold
    }

    var daysUntilExpiration: Int? {
        guard let expirationDate else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: expirationDate)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }
}
