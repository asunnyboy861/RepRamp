import Foundation
import SwiftData

struct SessionEntry: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let targetSets: Int
    let restSeconds: Int
    var targetReps: Int
    var weight: Double
    var reps: Int
    var completedSets: Int = 0
    var lastWeight: Double?
    var lastReps: Int?
    var isPR: Bool = false
}

struct WorkoutSummary: Identifiable {
    let id = UUID()
    let sessionName: String
    let duration: TimeInterval
    let volume: Double
    let sets: Int
    let personalRecords: [String]
    let xpGained: Int
    let rank: RepRank
    let leveledUp: Bool
    let streak: Int
}

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    @Published var entries: [SessionEntry]
    @Published var restRemaining = 0
    @Published var restTotal = 0
    @Published var summary: WorkoutSummary?
    @Published var errorMessage: String?
    @Published var showRankUp = false
    @Published var newRank: RepRank = .unranked

    let sessionName: String
    private let workouts: [Workout]
    private weak var progress: UserProgress?
    private var workout: Workout?
    private var timer: Timer?
    private var xpGained = 0
    private var prNames: [String] = []
    private var didFinish = false

    init(sessionName: String, items: [TodayItem], workouts: [Workout], progress: UserProgress?) {
        self.sessionName = sessionName
        self.workouts = workouts
        self.progress = progress
        self.entries = items.map { item in
            let defaultWeight: Double
            if item.suggestion.targetWeightLB > 0 {
                defaultWeight = item.suggestion.targetWeightLB
            } else {
                switch item.exercise.equipment.lowercased() {
                case "barbell": defaultWeight = 45
                case "dumbbell", "kettlebells": defaultWeight = 10
                default: defaultWeight = 0
                }
            }
            return SessionEntry(
                exercise: item.exercise,
                targetSets: item.planItem.targetSets,
                restSeconds: item.planItem.restSeconds,
                targetReps: item.suggestion.targetReps,
                weight: defaultWeight,
                reps: item.suggestion.targetReps,
                lastWeight: item.lastWeight,
                lastReps: item.lastReps
            )
        }
    }

    var totalCompletedSets: Int { entries.reduce(0) { $0 + $1.completedSets } }
    var hasCompletedSet: Bool { totalCompletedSets > 0 }
    var completedAll: Bool { entries.allSatisfy { $0.completedSets >= $0.targetSets } }
    var volumeSoFar: Double { entries.reduce(0) { $0 + Double($1.completedSets) * $1.weight * Double($1.reps) } }

    func startIfNeeded(context: ModelContext) {
        guard workout == nil else { return }
        workout = WorkoutRepository.startWorkout(sessionName: sessionName, context: context)
    }

    func adjustWeight(index: Int, delta: Double) {
        guard entries.indices.contains(index) else { return }
        let increment = entries[index].exercise.equipment.lowercased() == "barbell" ? 5.0 : max(2.5, delta)
        entries[index].weight = max(0, entries[index].weight + (delta > 0 ? increment : -increment))
    }

    func adjustReps(index: Int, delta: Int) {
        guard entries.indices.contains(index) else { return }
        entries[index].reps = min(40, max(1, entries[index].reps + delta))
    }

    func completeSet(index: Int, context: ModelContext) {
        guard entries.indices.contains(index) else { return }
        startIfNeeded(context: context)
        guard let workout else { return }
        let entry = entries[index]
        let previousBest = WorkoutRepository.bestEstimated1RM(for: entry.exercise.name, workouts: workouts, excluding: workout)
        let set = WorkoutRepository.addSet(
            workout: workout,
            exercise: entry.exercise,
            weight: entry.weight,
            reps: entry.reps,
            rpe: nil,
            isWarmup: false,
            context: context
        )
        var gained = 10
        if previousBest > 0 && set.estimated1RM > previousBest + 0.5 {
            gained += 100
            if !prNames.contains(entry.exercise.name) {
                prNames.append(entry.exercise.name)
            }
            entries[index].isPR = true
        }
        xpGained += gained
        entries[index].completedSets += 1
        if let progress {
            let change = RankEngine.award(gained, to: progress)
            if change.leveledUp {
                newRank = change.newRank
                showRankUp = true
            }
        }
        try? context.save()
        startRest(seconds: entry.restSeconds)
    }

    func startRest(seconds: Int) {
        timer?.invalidate()
        restTotal = max(0, seconds)
        restRemaining = max(0, seconds)
        guard seconds > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.restRemaining > 0 {
                    self.restRemaining -= 1
                } else {
                    self.timer?.invalidate()
                }
            }
        }
    }

    func skipRest() {
        timer?.invalidate()
        restRemaining = 0
    }

    func finish(context: ModelContext) {
        guard !didFinish, let workout else { return }
        didFinish = true
        timer?.invalidate()
        WorkoutRepository.finish(workout: workout, progress: progress, context: context)

        if let progress {
            let thisWeek = ProgressAnalytics.weeklyVolume(for: workouts + [workout], weeksAgo: 0)
            let lastWeek = ProgressAnalytics.weeklyVolume(for: workouts, weeksAgo: 1)
            let calendar = Calendar.current
            let alreadyBonus = progress.lastWeeklyBonusAt.map { calendar.isDate($0, equalTo: .now, toGranularity: .weekOfYear) } ?? false
            if lastWeek > 0, thisWeek > lastWeek, !alreadyBonus {
                _ = RankEngine.award(50, to: progress)
                progress.lastWeeklyBonusAt = .now
                xpGained += 50
            }
            try? context.save()
        }

        let duration = Date.now.timeIntervalSince(workout.startedAt)
        summary = WorkoutSummary(
            sessionName: sessionName,
            duration: duration,
            volume: workout.totalVolume,
            sets: workout.workingSets.count,
            personalRecords: prNames,
            xpGained: xpGained,
            rank: progress?.rank ?? .unranked,
            leveledUp: showRankUp,
            streak: progress?.streak ?? 0
        )

        Task {
            await HealthKitService.shared.saveWorkout(start: workout.startedAt, end: .now)
        }
    }

    func discard(context: ModelContext) {
        timer?.invalidate()
        if let workout {
            context.delete(workout)
            try? context.save()
        }
    }

    deinit {
        timer?.invalidate()
    }
}
