import Foundation
import SwiftData

@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var workout: Workout?
    var exercise: Exercise?
    var exerciseNameSnapshot: String
    var weightLB: Double
    var reps: Int
    var rpe: Double?
    var isWarmup: Bool
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var feedback: String

    init(workout: Workout?, exercise: Exercise?, weightLB: Double, reps: Int, rpe: Double? = nil, isWarmup: Bool = false) {
        self.id = UUID()
        self.workout = workout
        self.exercise = exercise
        self.exerciseNameSnapshot = exercise?.name ?? ""
        self.weightLB = weightLB
        self.reps = reps
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isDeleted = false
        self.createdAt = .now
        self.updatedAt = .now
        self.feedback = ""
    }

    var estimated1RM: Double {
        RampCoach.estimated1RM(weight: weightLB, reps: reps)
    }
}
