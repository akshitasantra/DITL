import Foundation

struct Activity: Identifiable {
    let id: Int            // SQLite row id
    var title: String
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int?
}

