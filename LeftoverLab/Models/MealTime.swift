import Foundation

enum MealTime: String, Codable, CaseIterable, Identifiable, Hashable {
    case breakfast, lunch, snack, dinner

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .snack: "Snacks"
        case .dinner: "Dinner"
        }
    }

    var systemImage: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .snack: "cup.and.saucer.fill"
        case .dinner: "moon.stars.fill"
        }
    }

    static func current(_ date: Date = Date()) -> MealTime {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<11: .breakfast
        case 11..<16: .lunch
        case 16..<19: .snack
        default: .dinner
        }
    }
}
