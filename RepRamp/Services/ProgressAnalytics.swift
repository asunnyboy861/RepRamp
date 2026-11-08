import Foundation

struct WeeklyVolume: Identifiable {
    let id = UUID()
    let weekStart: Date
    let volume: Double
}

struct MuscleVolume: Identifiable {
    let id = UUID()
    let muscle: String
    let sets: Int
}

struct PersonalRecord: Identifiable {
    let id = UUID()
    let exerciseName: String
    let estimated1RM: Double
    let weight: Double
    let reps: Int
    let achievedAt: Date
}

struct ProgressSnapshot {
    let thisWeekVolume: Double
    let lastWeekVolume: Double
    let weeklyDeltaPercent: Double
    let totalWorkouts: Int
    let totalVolume: Double
    let weeklyVolumes: [WeeklyVolume]
    let muscleVolumes: [MuscleVolume]
    let personalRecords: [PersonalRecord]
    let streak: Int
    let bestStreak: Int
    let totalSets: Int
}

enum ProgressAnalytics {
    static func snapshot(workouts: [Workout], streak: Int, bestStreak: Int) -> ProgressSnapshot {
        let finished = workouts.filter { $0.isFinished }
        let calendar = Calendar.current
        let now = Date.now

        var weekly: [WeeklyVolume] = []
        for offset in stride(from: 7, through: 0, by: -1) {
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -offset, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: weekDate) else { continue }
            let volume = finished
                .filter { $0.startedAt >= interval.start && $0.startedAt < interval.end }
                .reduce(0) { $0 + $1.totalVolume }
            weekly.append(WeeklyVolume(weekStart: interval.start, volume: volume))
        }

        let thisWeek = weekly.last?.volume ?? 0
        let lastWeek = weekly.count >= 2 ? weekly[weekly.count - 2].volume : 0
        let delta = lastWeek > 0 ? (thisWeek - lastWeek) / lastWeek * 100 : (thisWeek > 0 ? 100 : 0)

        var muscleCounts: [String: Int] = [:]
        let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        for workout in finished where workout.startedAt >= cutoff {
            for set in workout.workingSets {
                guard let exercise = set.exercise else { continue }
                for muscle in exercise.muscleGroups.prefix(2) {
                    muscleCounts[muscle, default: 0] += 1
                }
            }
        }
        let muscles = muscleCounts.map { MuscleVolume(muscle: $0.key.capitalized, sets: $0.value) }
            .sorted { $0.sets > $1.sets }
            .prefix(10)

        var prs: [String: PersonalRecord] = [:]
        for workout in finished {
            for set in workout.workingSets where set.exercise != nil {
                let name = set.exercise?.name ?? set.exerciseNameSnapshot
                let estimate = set.estimated1RM
                if let existing = prs[name], existing.estimated1RM >= estimate { continue }
                prs[name] = PersonalRecord(exerciseName: name, estimated1RM: estimate, weight: set.weightLB, reps: set.reps, achievedAt: set.createdAt)
            }
        }
        let records = prs.values.sorted { $0.estimated1RM > $1.estimated1RM }.prefix(8).map { $0 }

        return ProgressSnapshot(
            thisWeekVolume: thisWeek,
            lastWeekVolume: lastWeek,
            weeklyDeltaPercent: delta,
            totalWorkouts: finished.count,
            totalVolume: finished.reduce(0) { $0 + $1.totalVolume },
            weeklyVolumes: weekly,
            muscleVolumes: Array(muscles),
            personalRecords: records,
            streak: streak,
            bestStreak: bestStreak,
            totalSets: finished.reduce(0) { $0 + $1.workingSets.count }
        )
    }

    static func weeklyVolume(for workouts: [Workout], weeksAgo: Int) -> Double {
        let calendar = Calendar.current
        guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: .now),
              let interval = calendar.dateInterval(of: .weekOfYear, for: weekDate) else { return 0 }
        return workouts.filter { $0.isFinished && $0.startedAt >= interval.start && $0.startedAt < interval.end }
            .reduce(0) { $0 + $1.totalVolume }
    }
}
