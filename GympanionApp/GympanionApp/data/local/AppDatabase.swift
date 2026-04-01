// GympanionApp/data/local/AppDatabase.swift
import Foundation
import SwiftData

@MainActor
final class AppDatabase {
    static let shared = AppDatabase()

    let container: ModelContainer

    private init() {
        let schema = Schema([ExerciseEntity.self, WorkoutEntity.self, SessionEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var mainContext: ModelContext { container.mainContext }
}
