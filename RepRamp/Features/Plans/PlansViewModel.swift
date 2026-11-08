import SwiftUI
import SwiftData

@MainActor
final class PlansViewModel: ObservableObject {
    @Published var errorMessage: String?

    func create(answers: PlanQuestionnaire, context: ModelContext) {
        let sessions = PlanTemplates.makePlan(from: answers)
        PlanRepository.create(name: PlanTemplates.planName(from: answers), goal: answers.goal, sessions: sessions, source: "builtin", context: context)
    }

    func setActive(_ plan: Plan, context: ModelContext) {
        PlanRepository.setActive(plan, context: context)
    }

    func delete(_ plan: Plan, context: ModelContext) {
        PlanRepository.delete(plan, context: context)
    }

    func addExercise(named name: String, to sessionIndex: Int, plan: Plan, context: ModelContext, exercises: [Exercise]) {
        var sessions = plan.sessions
        guard sessions.indices.contains(sessionIndex) else { return }
        let exercise = ExerciseRepository.ensureExercise(named: name, in: exercises, context: context)
        sessions[sessionIndex].items.append(PlanItem(exerciseName: exercise.name, targetSets: 3, targetRepsMin: 8, targetRepsMax: 12, restSeconds: 90))
        PlanRepository.updateSessions(sessions, on: plan, context: context)
    }

    func removeExercise(sessionIndex: Int, itemIndex: Int, plan: Plan, context: ModelContext) {
        var sessions = plan.sessions
        guard sessions.indices.contains(sessionIndex), sessions[sessionIndex].items.indices.contains(itemIndex) else { return }
        sessions[sessionIndex].items.remove(at: itemIndex)
        PlanRepository.updateSessions(sessions, on: plan, context: context)
    }

    func update(_ sessions: [PlanSession], plan: Plan, context: ModelContext) {
        PlanRepository.updateSessions(sessions, on: plan, context: context)
    }
}
