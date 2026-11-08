import Foundation
import SwiftData

enum WorkoutRepository {
    @discardableResult
    static func startWorkout(sessionName: String, context: ModelContext) -> Workout {
        let workout = Workout(startedAt: .now, planSessionName: sessionName)
        context.insert(workout)
        try? context.save()
        return workout
    }

    @discardableResult
    static func addSet(workout: Workout, exercise: Exercise, weight: Double, reps: Int, rpe: Double?, isWarmup: Bool, context: ModelContext) -> SetEntry {
        let entry = SetEntry(workout: workout, exercise: exercise, weightLB: weight, reps: reps, rpe: rpe, isWarmup: isWarmup)
        context.insert(entry)
        workout.sets.append(entry)
        try? context.save()
        return entry
    }

    static func finish(workout: Workout, progress: UserProgress?, context: ModelContext) {
        workout.finishedAt = .now
        if let progress {
            RankEngine.registerWorkoutDay(.now, progress: progress)
        }
        try? context.save()
    }

    static func softDelete(_ entry: SetEntry, context: ModelContext) {
        entry.isDeleted = true
        entry.updatedAt = .now
        try? context.save()
    }

    static func history(for exerciseName: String, workouts: [Workout], limitDays: Int = 120) -> [SetEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -limitDays, to: .now) ?? .distantPast
        return workouts
            .flatMap { $0.sets }
            .filter { !$0.isDeleted && !$0.isWarmup && $0.createdAt >= cutoff }
            .filter { ($0.exercise?.name ?? $0.exerciseNameSnapshot) == exerciseName }
            .sorted { $0.createdAt < $1.createdAt }
    }

    static func bestEstimated1RM(for exerciseName: String, workouts: [Workout], excluding workout: Workout? = nil) -> Double {
        workouts
            .filter { $0.id != workout?.id }
            .flatMap { $0.sets }
            .filter { !$0.isDeleted && !$0.isWarmup && ($0.exercise?.name ?? $0.exerciseNameSnapshot) == exerciseName }
            .map { $0.estimated1RM }
            .max() ?? 0
    }

    static func lastPerformance(for exerciseName: String, workouts: [Workout]) -> (weight: Double, reps: Int)? {
        guard let last = history(for: exerciseName, workouts: workouts).last else { return nil }
        return (last.weightLB, last.reps)
    }

    static func setFeedback(_ entry: SetEntry, feedback: String, context: ModelContext) {
        entry.feedback = feedback
        entry.updatedAt = .now
        try? context.save()
    }
}
