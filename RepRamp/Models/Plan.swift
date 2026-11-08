import Foundation
import SwiftData

struct PlanItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var exerciseName: String
    var targetSets: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    var restSeconds: Int

    enum CodingKeys: String, CodingKey {
        case exerciseName, targetSets, targetRepsMin, targetRepsMax, restSeconds
    }

    init(exerciseName: String, targetSets: Int, targetRepsMin: Int, targetRepsMax: Int, restSeconds: Int) {
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.restSeconds = restSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        targetSets = try container.decode(Int.self, forKey: .targetSets)
        targetRepsMin = try container.decode(Int.self, forKey: .targetRepsMin)
        targetRepsMax = try container.decode(Int.self, forKey: .targetRepsMax)
        restSeconds = try container.decode(Int.self, forKey: .restSeconds)
    }
}

struct PlanSession: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var dayName: String
    var items: [PlanItem]

    enum CodingKeys: String, CodingKey {
        case dayName, items
    }

    init(dayName: String, items: [PlanItem]) {
        self.dayName = dayName
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        dayName = try container.decode(String.self, forKey: .dayName)
        items = try container.decode([PlanItem].self, forKey: .items)
    }
}

@Model
final class Plan {
    @Attribute(.unique) var id: UUID
    var name: String
    var goal: String
    var source: String
    var createdAt: Date
    var isActive: Bool
    var sessionsData: Data

    init(name: String, goal: String, sessions: [PlanSession], source: String, isActive: Bool = false) {
        self.id = UUID()
        self.name = name
        self.goal = goal
        self.source = source
        self.createdAt = .now
        self.isActive = isActive
        self.sessionsData = (try? JSONEncoder().encode(sessions)) ?? Data()
    }

    var sessions: [PlanSession] {
        get { (try? JSONDecoder().decode([PlanSession].self, from: sessionsData)) ?? [] }
        set { sessionsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var exerciseCount: Int {
        sessions.reduce(0) { $0 + $1.items.count }
    }
}
