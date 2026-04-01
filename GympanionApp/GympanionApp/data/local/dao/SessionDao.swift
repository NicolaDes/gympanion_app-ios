// GympanionApp/data/local/dao/SessionDao.swift
import Foundation
import SwiftData

final class SessionDao {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func fetchAll() throws -> [SessionEntity] {
        try modelContext.fetch(FetchDescriptor<SessionEntity>())
    }

    func fetchById(_ id: String) throws -> SessionEntity? {
        let descriptor = FetchDescriptor<SessionEntity>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    func insert(_ entity: SessionEntity) throws {
        modelContext.insert(entity)
        try modelContext.save()
    }

    func delete(id: String) throws {
        guard let entity = try fetchById(id) else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }
}
