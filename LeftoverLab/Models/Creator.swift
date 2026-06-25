import Foundation
import SwiftData

@Model
final class Creator {
    var name: String
    var channelURL: String
    var dateAdded: Date

    init(name: String, channelURL: String = "") {
        self.name = name
        self.channelURL = channelURL
        self.dateAdded = Date()
    }
}
