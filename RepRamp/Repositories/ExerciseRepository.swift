import Foundation
import SwiftData

struct SeedExercise: Decodable {
    let name: String
    let force: String?
    let level: String?
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]?
    let instructions: [String]
    let category: String?
}

enum ExerciseRepository {
    static let seedVersion = 1
    private static let seedKey = "RepRampExerciseSeedVersion"

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: seedKey) < seedVersion else { return }
        let count = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        if count == 0 {
            guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let seeds = try? JSONDecoder().decode([SeedExercise].self, from: data) else {
                return
            }
            for seed in seeds {
                let muscles = seed.primaryMuscles + (seed.secondaryMuscles ?? [])
                let exercise = Exercise(
                    name: seed.name,
                    muscleGroups: Array(muscles.prefix(4)),
                    equipment: seed.equipment ?? "body only",
                    instructions: seed.instructions.joined(separator: "\n"),
                    level: seed.level ?? "intermediate",
                    category: seed.category ?? "strength",
                    force: seed.force ?? ""
                )
                context.insert(exercise)
            }
            try? context.save()
        }
        defaults.set(seedVersion, forKey: seedKey)
    }

    static func resolve(name: String, in exercises: [Exercise]) -> Exercise? {
        if let exact = exercises.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return exact
        }
        if let contains = exercises.first(where: { $0.name.lowercased().contains(name.lowercased()) }) {
            return contains
        }
        let targetWords = Set(name.lowercased().split(separator: " ").map(String.init))
        let scored = exercises.map { exercise -> (Exercise, Int) in
            let words = Set(exercise.name.lowercased().split(separator: " ").map(String.init))
            return (exercise, targetWords.intersection(words).count)
        }
        return scored.filter { $0.1 >= 2 }.max { $0.1 < $1.1 }?.0
    }

    static func ensureExercise(named name: String, in exercises: [Exercise], context: ModelContext) -> Exercise {
        if let found = resolve(name: name, in: exercises) { return found }
        let custom = Exercise(name: name, muscleGroups: ["full body"], equipment: "other", isCustom: true)
        context.insert(custom)
        return custom
    }

    static func createCustom(name: String, muscles: [String], equipment: String, context: ModelContext) -> Exercise {
        let exercise = Exercise(name: name, muscleGroups: muscles, equipment: equipment, isCustom: true)
        context.insert(exercise)
        try? context.save()
        return exercise
    }

    static func search(query: String, in exercises: [Exercise], muscle: String?) -> [Exercise] {
        var results = exercises
        if let muscle, !muscle.isEmpty {
            results = results.filter { $0.muscleGroups.contains { $0.localizedCaseInsensitiveContains(muscle) } }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return results }
        return results.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) ||
            $0.muscleGroups.contains { $0.localizedCaseInsensitiveContains(trimmed) } ||
            $0.equipment.localizedCaseInsensitiveContains(trimmed)
        }
    }

    static var muscleOptions: [String] {
        ["chest", "lats", "quadriceps", "hamstrings", "shoulders", "biceps", "triceps", "abdominals", "glutes", "calves"]
    }
}
