import SwiftUI
import SwiftData
import PhotosUI
import UIKit

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var goal = PlanTemplates.goals[0]
    @Published var experience = PlanTemplates.experienceLevels[1]
    @Published var location = PlanTemplates.locations[0]
    @Published var days = 4
    @Published var isGenerating = false
    @Published var draft: PlanDraft?
    @Published var errorMessage: String?
    @Published var screenshotItem: PhotosPickerItem?
    @Published var screenshotData: Data?
    @Published var isImporting = false

    func generate() async {
        isGenerating = true
        errorMessage = nil
        draft = nil
        do {
            draft = try await AIGateway.shared.generatePlan(PlanQuestionnaire(goal: goal, experience: experience, location: location, daysPerWeek: days))
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }

    func loadScreenshot(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            errorMessage = "That screenshot could not be read."
            return
        }
        screenshotData = ImageCompressor.jpeg(from: image)
    }

    func importScreenshot() async {
        guard let screenshotData else { return }
        isImporting = true
        errorMessage = nil
        draft = nil
        do {
            draft = try await AIGateway.shared.importScreenshot(image: screenshotData)
        } catch {
            errorMessage = error.localizedDescription
        }
        isImporting = false
    }

    func saveDraft(context: ModelContext, exercises: [Exercise]) -> Bool {
        guard let draft else { return false }
        var sessions: [PlanSession] = []
        for session in draft.sessions {
            var items: [PlanItem] = []
            for item in session.items {
                let exercise = ExerciseRepository.ensureExercise(named: item.exerciseName, in: exercises, context: context)
                items.append(PlanItem(exerciseName: exercise.name, targetSets: item.targetSets, targetRepsMin: item.targetRepsMin, targetRepsMax: item.targetRepsMax, restSeconds: item.restSeconds))
            }
            sessions.append(PlanSession(dayName: session.dayName, items: items))
        }
        guard !sessions.isEmpty else { return false }
        PlanRepository.create(name: draft.name, goal: draft.goal, sessions: sessions, source: "ai", context: context)
        self.draft = nil
        return true
    }
}
