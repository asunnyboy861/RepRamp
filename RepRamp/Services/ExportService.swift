import Foundation

struct ExportSetDTO: Codable {
    let exercise: String
    let weight_lb: Double
    let reps: Int
    let rpe: Double?
    let warmup: Bool
    let deleted: Bool
    let created_at: String
}

struct ExportWorkoutDTO: Codable {
    let workout_id: String
    let started_at: String
    let finished_at: String?
    let session: String
    let notes: String
    let volume_lb: Double
    let sets: [ExportSetDTO]
}

enum ExportService {
    private static var formatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    static func makeJSON(workouts: [Workout]) -> URL? {
        let payload = workouts.map { workout in
            ExportWorkoutDTO(
                workout_id: workout.id.uuidString,
                started_at: formatter.string(from: workout.startedAt),
                finished_at: workout.finishedAt.map { formatter.string(from: $0) },
                session: workout.planSessionName,
                notes: workout.notes,
                volume_lb: workout.totalVolume,
                sets: workout.sets.map { set in
                    ExportSetDTO(
                        exercise: set.exercise?.name ?? set.exerciseNameSnapshot,
                        weight_lb: set.weightLB,
                        reps: set.reps,
                        rpe: set.rpe,
                        warmup: set.isWarmup,
                        deleted: set.isDeleted,
                        created_at: formatter.string(from: set.createdAt)
                    )
                }
            )
        }
        guard let data = try? JSONEncoder.pretty.encode(payload) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RepRamp-backup.json")
        try? data.write(to: url)
        return url
    }

    static func makeCSV(workouts: [Workout]) -> URL? {
        var lines = ["date,session,exercise,weight_lb,reps,rpe,warmup,deleted,estimated_1rm"]
        for workout in workouts {
            for set in workout.sets {
                let name = (set.exercise?.name ?? set.exerciseNameSnapshot).replacingOccurrences(of: ",", with: " ")
                let date = formatter.string(from: set.createdAt)
                let rpe = set.rpe.map { String(format: "%.1f", $0) } ?? ""
                lines.append("\(date),\(workout.planSessionName.replacingOccurrences(of: ",", with: " ")),\(name),\(String(format: "%.1f", set.weightLB)),\(set.reps),\(rpe),\(set.isWarmup),\(set.isDeleted),\(String(format: "%.1f", set.estimated1RM))")
            }
        }
        guard let data = lines.joined(separator: "\n").data(using: .utf8) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RepRamp-log.csv")
        try? data.write(to: url)
        return url
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
