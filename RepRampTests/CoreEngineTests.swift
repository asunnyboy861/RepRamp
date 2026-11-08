import XCTest
@testable import RepRamp

final class RampCoachTests: XCTestCase {
    private func makeExercise(name: String = "Barbell Bench Press", equipment: String = "barbell") -> Exercise {
        Exercise(name: name, muscleGroups: ["chest"], equipment: equipment)
    }

    private func makeSet(weight: Double, reps: Int, rpe: Double?, at date: Date = .now, feedback: String = "") -> SetEntry {
        let exercise = makeExercise()
        let set = SetEntry(workout: nil, exercise: exercise, weightLB: weight, reps: reps, rpe: rpe)
        set.createdAt = date
        set.feedback = feedback
        return set
    }

    func testEstimatedOneRepMax() {
        XCTAssertEqual(RampCoach.estimated1RM(weight: 100, reps: 1), 100)
        XCTAssertEqual(RampCoach.estimated1RM(weight: 100, reps: 10), 133.33, accuracy: 0.1)
        XCTAssertEqual(RampCoach.estimated1RM(weight: 0, reps: 0), 0)
    }

    func testIncrementByEquipment() {
        XCTAssertEqual(RampCoach.increment(for: "barbell"), 5)
        XCTAssertEqual(RampCoach.increment(for: "dumbbell"), 5)
        XCTAssertEqual(RampCoach.increment(for: "cable"), 2.5)
        XCTAssertEqual(RampCoach.increment(for: "body only"), 2.5)
    }

    func testAddRepBeforeLoad() {
        let history = [makeSet(weight: 135, reps: 8, rpe: 8)]
        let suggestion = RampCoach.nextSuggestion(history: history, equipment: "barbell", plannedRepMax: 12)
        XCTAssertEqual(suggestion?.targetWeightLB, 135)
        XCTAssertEqual(suggestion?.targetReps, 9)
    }

    func testAddLoadAtRepCeilingWithinCap() {
        let history = [makeSet(weight: 135, reps: 12, rpe: 8)]
        let suggestion = RampCoach.nextSuggestion(history: history, equipment: "barbell", plannedRepMax: 12)
        XCTAssertEqual(suggestion?.targetWeightLB, 140)
        XCTAssertLessThanOrEqual(suggestion?.targetReps ?? 0, 10)
    }

    func testHighRpeConsolidates() {
        let history = [makeSet(weight: 135, reps: 8, rpe: 9.5)]
        let suggestion = RampCoach.nextSuggestion(history: history, equipment: "barbell", plannedRepMax: 12)
        XCTAssertEqual(suggestion?.targetWeightLB, 135)
        XCTAssertEqual(suggestion?.targetReps, 8)
    }

    func testTooLightFeedbackAddsLoad() {
        let history = [makeSet(weight: 100, reps: 8, rpe: 7, feedback: "tooLight")]
        let suggestion = RampCoach.nextSuggestion(history: history, equipment: "barbell")
        XCTAssertEqual(suggestion?.targetWeightLB, 105)
    }

    func testRecoveryTrim() {
        let history = [makeSet(weight: 135, reps: 10, rpe: 8)]
        let suggestion = RampCoach.nextSuggestion(history: history, equipment: "barbell", recoveryFactor: 0.65)
        XCTAssertNotNil(suggestion?.caution)
        XCTAssertLessThan(suggestion?.targetWeightLB ?? 0, 135)
    }

    func testFirstTimeHasNoHistory() {
        let suggestion = RampCoach.firstTimeSuggestion(exerciseName: "Squat", plannedSets: 3, plannedReps: 8)
        XCTAssertFalse(suggestion.hasHistory)
        XCTAssertEqual(suggestion.targetWeightLB, 0)
    }
}

final class RankEngineTests: XCTestCase {
    func testRankThresholds() {
        XCTAssertEqual(RankEngine.rank(for: 0), .unranked)
        XCTAssertEqual(RankEngine.rank(for: 99), .unranked)
        XCTAssertEqual(RankEngine.rank(for: 100), .bronze)
        XCTAssertEqual(RankEngine.rank(for: 350), .silver)
        XCTAssertEqual(RankEngine.rank(for: 9500), .legend)
    }

    func testXPProgressAndNext() {
        XCTAssertEqual(RankEngine.xpProgress(for: 200), 100)
        XCTAssertEqual(RankEngine.xpToNext(for: 200), 150)
        XCTAssertEqual(RankEngine.rankProgressFraction(for: 100), 0)
        XCTAssertEqual(RankEngine.rankProgressFraction(for: 9500), 1)
    }

    func testWorkoutDayStreak() {
        let progress = UserProgress()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        RankEngine.registerWorkoutDay(yesterday, progress: progress)
        XCTAssertEqual(progress.streak, 1)
        RankEngine.registerWorkoutDay(.now, progress: progress)
        XCTAssertEqual(progress.streak, 2)
        XCTAssertEqual(progress.bestStreak, 2)
    }
}

final class PlanTemplateTests: XCTestCase {
    func testTemplateSessionCount() {
        for days in PlanTemplates.dayOptions {
            let answers = PlanQuestionnaire(goal: "Build Muscle", experience: "Intermediate", location: "Gym", daysPerWeek: days)
            XCTAssertEqual(PlanTemplates.makePlan(from: answers).count, days)
        }
    }

    func testHomeTemplateHasItems() {
        let answers = PlanQuestionnaire(goal: "General Health", experience: "Beginner", location: "Home", daysPerWeek: 3)
        let sessions = PlanTemplates.makePlan(from: answers)
        XCTAssertEqual(sessions.count, 3)
        XCTAssertFalse(sessions[0].items.isEmpty)
        XCTAssertTrue(sessions[0].items.allSatisfy { $0.targetSets >= 1 && $0.targetRepsMax >= $0.targetRepsMin })
    }
}

final class AIValidatorTests: XCTestCase {
    func testPlanDraftClampsValues() throws {
        let json = """
        {"name":"Test","goal":"Build Muscle","sessions":[{"dayName":"Push","items":[{"exerciseName":"Bench Press","targetSets":12,"targetRepsMin":3,"targetRepsMax":50,"restSeconds":5}]}]}
        """
        let draft = try AIResponseValidator.planDraft(from: json)
        XCTAssertEqual(draft.sessions.count, 1)
        XCTAssertEqual(draft.sessions[0].items[0].targetSets, 6)
        XCTAssertEqual(draft.sessions[0].items[0].restSeconds, 30)
        XCTAssertEqual(draft.sessions[0].items[0].targetRepsMax, 40)
    }

    func testInvalidPlanThrows() {
        XCTAssertThrowsError(try AIResponseValidator.planDraft(from: "not json"))
    }
}
