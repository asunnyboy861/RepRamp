import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var finishedAt: Date?
    var planSessionName: String
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.workout) var sets: [SetEntry]

    init(startedAt: Date = .now, planSessionName: String = "") {
        self.id = UUID()
        self.startedAt = startedAt
        self.finishedAt = nil
        self.planSessionName = planSessionName
        self.notes = ""
        self.sets = []
    }

    var isFinished: Bool { finishedAt != nil }

    var workingSets: [SetEntry] {
        sets.filter { !$0.isDeleted && !$0.isWarmup }
    }

    var totalVolume: Double {
        workingSets.reduce(0) { $0 + $1.weightLB * Double($1.reps) }
    }

    var totalReps: Int {
        workingSets.reduce(0) { $0 + $1.reps }
    }
}
