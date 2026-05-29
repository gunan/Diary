import Foundation
import OSLog

enum AppLog {
    private static let persistence = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.gunan.PersonalTracker",
        category: "Persistence"
    )

    static func persistenceError(_ message: String) {
        persistence.error("\(message, privacy: .public)")
    }
}
