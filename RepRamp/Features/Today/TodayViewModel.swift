import Foundation
import SwiftData

struct TodayItem: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let planItem: PlanItem
    let suggestion: RampSuggestion
    let lastWeight: Double?
    let lastReps: Int?
    let lastEntry: SetEntry?
}

struct TodaySnapshot {
    let planName: String
    let sessionName: String
    let items: [TodayItem]
    let finishedToday: Bool
    let rank: RepRank
    let totalXP: Int
    let xpFraction: Double
    let xpToNext: Int
    let streak: Int
    let recoveryNote: String?
    let completedWorkouts: Int
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var snapshot: TodaySnapshot?

    func load(plans: [Plan], workouts: [Workout], progress: UserProgress?, exercises: [Exercise], recoveryFactor: Double?, recoveryNote: String?, context: ModelContext) {
        guard let plan = PlanRepository.activePlan(from: plans), !plan.sessions.isEmpty else {
            snapshot = nil
            return
        }
        let sessions = plan.sessions
        let finished = workouts.filter { $0.isFinished }
        let index = sessions.isEmpty ? 0 : finished.count % sessions.count
        let session = sessions[index]
        let finishedToday = finished.contains { $0.finishedAt.map { Calendar.current.isDateInToday($0) } ?? false }

        var items: [TodayItem] = []
        for planItem in session.items {
            let exercise = ExerciseRepository.ensureExercise(named: planItem.exerciseName, in: exercises, context: context)
            let history = WorkoutRepository.history(for: exercise.name, workouts: workouts)
            let suggestion = RampCoach.nextSuggestion(
                history: history,
                equipment: exercise.equipment,
                recoveryFactor: recoveryFactor,
                plannedSets: planItem.targetSets,
                plannedRepMin: planItem.targetRepsMin,
                plannedRepMax: planItem.targetRepsMax
            ) ?? RampCoach.firstTimeSuggestion(exerciseName: exercise.name, plannedSets: planItem.targetSets, plannedReps: planItem.targetRepsMax)
            let last = history.last
            items.append(TodayItem(exercise: exercise, planItem: planItem, suggestion: suggestion, lastWeight: last?.weightLB, lastReps: last?.reps, lastEntry: last))
        }

        let rank = progress?.rank ?? .unranked
        let xp = progress?.totalXP ?? 0
        snapshot = TodaySnapshot(
            planName: plan.name,
            sessionName: session.dayName,
            items: items,
            finishedToday: finishedToday,
            rank: rank,
            totalXP: xp,
            xpFraction: RankEngine.rankProgressFraction(for: xp),
            xpToNext: RankEngine.xpToNext(for: xp),
            streak: progress?.streak ?? 0,
            recoveryNote: recoveryNote,
            completedWorkouts: finished.count
        )
    }
}
