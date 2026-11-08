#if DEBUG
import Foundation
import SwiftData

enum QASeed {
    static func apply(context: ModelContext) {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--qa-seed") else { return }
        UserDefaults.standard.set(true, forKey: "hasOnboarded")

        let plans = (try? context.fetch(FetchDescriptor<Plan>())) ?? []
        if PlanRepository.activePlan(from: plans) == nil {
            let answers = PlanQuestionnaire(goal: "Build Muscle", experience: "Intermediate", location: "Gym", daysPerWeek: 4)
            PlanRepository.create(name: "Build Muscle • 4 Days", goal: answers.goal, sessions: PlanTemplates.makePlan(from: answers), source: "builtin", context: context)
        }

        guard args.contains("--qa-history") else { return }
        let existingWorkouts = (try? context.fetchCount(FetchDescriptor<Workout>())) ?? 0
        guard existingWorkouts == 0 else { return }

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let history: [(String, Double, Int)] = [
            ("Barbell Bench Press - Medium Grip", 135, 8),
            ("Bent Over Barbell Row", 115, 8),
            ("Dumbbell Shoulder Press", 50, 10),
            ("Barbell Squat", 185, 8),
            ("Lying Leg Curls", 90, 12),
            ("Side Lateral Raise", 25, 12)
        ]

        let progress = (try? context.fetch(FetchDescriptor<UserProgress>()))?.first

        for week in stride(from: 5, through: 0, by: -1) {
            guard let date = Calendar.current.date(byAdding: .day, value: -(week * 3), to: .now) else { continue }
            let workout = Workout(startedAt: date, planSessionName: week % 2 == 0 ? "Upper A" : "Lower A")
            workout.finishedAt = date.addingTimeInterval(3600)
            context.insert(workout)
            for (offset, item) in history.enumerated() {
                guard let exercise = ExerciseRepository.resolve(name: item.0, in: exercises), offset < 4 else { continue }
                for setIndex in 0..<3 {
                    let set = SetEntry(
                        workout: workout,
                        exercise: exercise,
                        weightLB: item.1 + Double(5 - week) * 2.5,
                        reps: item.2 - setIndex,
                        rpe: 8
                    )
                    set.createdAt = date.addingTimeInterval(Double(offset * 600 + setIndex * 120))
                    context.insert(set)
                    workout.sets.append(set)
                }
            }
            if let progress {
                RankEngine.award(10 * 12, to: progress)
            }
        }
        try? context.save()
    }
}
#endif
