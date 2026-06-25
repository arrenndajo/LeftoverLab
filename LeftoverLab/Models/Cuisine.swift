import Foundation

enum Cuisine: String, Codable, CaseIterable, Identifiable, Hashable {
    case northIndian, southIndian, gujarati, maharashtrian, rajasthani, northEastern, western

    var id: String { rawValue }

    var label: String {
        switch self {
        case .northIndian: "North Indian"
        case .southIndian: "South Indian"
        case .gujarati: "Gujarati"
        case .maharashtrian: "Maharashtrian"
        case .rajasthani: "Rajasthani"
        case .northEastern: "North Eastern"
        case .western: "Western"
        }
    }

    static func decode(_ raw: String) -> Set<Cuisine> {
        Set(raw.split(separator: ",").compactMap { Cuisine(rawValue: String($0)) })
    }
    static func encode(_ set: Set<Cuisine>) -> String {
        set.map(\.rawValue).sorted().joined(separator: ",")
    }
}
