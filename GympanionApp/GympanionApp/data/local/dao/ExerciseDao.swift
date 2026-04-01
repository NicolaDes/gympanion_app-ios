// GympanionApp/data/local/dao/ExerciseDao.swift
import Foundation
import SwiftData

final class ExerciseDao {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func fetchAll() throws -> [ExerciseEntity] {
        try modelContext.fetch(FetchDescriptor<ExerciseEntity>())
    }

    func fetchById(_ id: String) throws -> ExerciseEntity? {
        let descriptor = FetchDescriptor<ExerciseEntity>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    func insert(_ entity: ExerciseEntity) throws {
        modelContext.insert(entity)
        try modelContext.save()
    }

    func delete(id: String) throws {
        guard let entity = try fetchById(id) else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }
}
