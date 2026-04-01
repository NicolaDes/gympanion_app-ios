// GympanionApp/data/local/dao/WorkoutDao.swift
import Foundation
import SwiftData

final class WorkoutDao {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func fetchAll() throws -> [WorkoutEntity] {
        try modelContext.fetch(FetchDescriptor<WorkoutEntity>())
    }

    func fetchById(_ id: String) throws -> WorkoutEntity? {
        let descriptor = FetchDescriptor<WorkoutEntity>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    func insert(_ entity: WorkoutEntity) throws {
        modelContext.insert(entity)
        try modelContext.save()
    }

    func delete(id: String) throws {
        guard let entity = try fetchById(id) else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }
}
