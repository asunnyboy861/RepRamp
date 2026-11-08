import Foundation
import SwiftData

enum PlanRepository {
    static func activePlan(from plans: [Plan]) -> Plan? {
        plans.first(where: { $0.isActive }) ?? plans.sorted(by: { $0.createdAt > $1.createdAt }).first
    }

    @discardableResult
    static func create(name: String, goal: String, sessions: [PlanSession], source: String, context: ModelContext, makeActive: Bool = true) -> Plan {
        if makeActive {
            let existing = (try? context.fetch(FetchDescriptor<Plan>())) ?? []
            existing.forEach { $0.isActive = false }
        }
        let plan = Plan(name: name, goal: goal, sessions: sessions, source: source, isActive: makeActive)
        context.insert(plan)
        try? context.save()
        return plan
    }

    static func setActive(_ plan: Plan, context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<Plan>())) ?? []
        all.forEach { $0.isActive = ($0.id == plan.id) }
        try? context.save()
    }

    static func delete(_ plan: Plan, context: ModelContext) {
        context.delete(plan)
        try? context.save()
    }

    static func updateSessions(_ sessions: [PlanSession], on plan: Plan, context: ModelContext) {
        plan.sessions = sessions
        try? context.save()
    }

    static func applyPriorities(_ priorities: [String], to plan: Plan, exercises: [Exercise], context: ModelContext) {
        var sessions = plan.sessions
        for sessionIndex in sessions.indices {
            for itemIndex in sessions[sessionIndex].items.indices {
                let name = sessions[sessionIndex].items[itemIndex].exerciseName
                guard let exercise = ExerciseRepository.resolve(name: name, in: exercises) else { continue }
                let matches = exercise.muscleGroups.contains { muscle in
                    priorities.contains { $0.localizedCaseInsensitiveContains(muscle) || muscle.localizedCaseInsensitiveContains($0) }
                }
                if matches {
                    sessions[sessionIndex].items[itemIndex].targetSets = min(6, sessions[sessionIndex].items[itemIndex].targetSets + 1)
                }
            }
        }
        plan.sessions = sessions
        try? context.save()
    }
}
