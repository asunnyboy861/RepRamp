import Foundation

struct RampSuggestion {
    let exerciseName: String
    let targetWeightLB: Double
    let targetSets: Int
    let targetReps: Int
    let reason: String
    let caution: String?
    let hasHistory: Bool
}

enum RampCoach {
    static func estimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return reps == 1 ? weight : weight * (1 + Double(reps) / 30.0)
    }

    static func increment(for equipment: String) -> Double {
        switch equipment.lowercased() {
        case "barbell":
            return 5.0
        case "dumbbell", "kettlebells", "kettlebell":
            return 5.0
        default:
            return 2.5
        }
    }

    static func roundedToPlate(_ value: Double) -> Double {
        guard value > 0 else { return 0 }
        let step = value >= 100 ? 5.0 : 2.5
        return (value / step).rounded() * step
    }

    static func firstTimeSuggestion(exerciseName: String, plannedSets: Int, plannedReps: Int) -> RampSuggestion {
        RampSuggestion(
            exerciseName: exerciseName,
            targetWeightLB: 0,
            targetSets: plannedSets,
            targetReps: plannedReps,
            reason: "First session for this lift. Pick a weight you can control for \(plannedReps) clean reps, then we ramp from there.",
            caution: nil,
            hasHistory: false
        )
    }

    static func nextSuggestion(history: [SetEntry], equipment: String, recoveryFactor: Double? = nil, plannedSets: Int = 3, plannedRepMin: Int = 8, plannedRepMax: Int = 12) -> RampSuggestion? {
        guard let last = history.sorted(by: { $0.createdAt < $1.createdAt }).last else { return nil }
        let name = last.exercise?.name ?? last.exerciseNameSnapshot
        var weight = last.weightLB
        var reps = last.reps
        var reason: String
        var caution: String? = nil

        let idleDays = Calendar.current.dateComponents([.day], from: last.createdAt, to: .now).day ?? 0

        if idleDays >= 14 && weight > 0 {
            weight = roundedToPlate(weight * 0.9)
            reps = max(plannedRepMin, reps)
            reason = "It has been \(idleDays) days since this lift. Ease back in about 10% lighter, then rebuild."
        } else if last.feedback == "tooHeavy" {
            weight = roundedToPlate(weight * 0.95)
            reason = "You flagged the last set as too heavy. Trim 5% and own the reps before ramping again."
        } else {
            let rpe = last.rpe ?? 7.5
            if last.feedback == "tooLight" {
                weight = min(weight + increment(for: equipment), weight * 1.10)
                weight = roundedToPlate(weight)
                reps = max(plannedRepMin, reps)
                reason = "You flagged the last set as too light. Add \(Int(increment(for: equipment))) lb and keep the rep target."
            } else if rpe <= 8.5 {
                if reps < plannedRepMax {
                    reps += 1
                    reason = "Last set was RPE \(String(format: "%.1f", rpe))/10. Add one rep at the same weight, then load up once you hit \(plannedRepMax)."
                } else {
                    let jump = min(increment(for: equipment), weight * 0.05, 10.0)
                    weight = roundedToPlate(weight + jump)
                    reps = max(5, reps - 2)
                    reason = "You hit the \(plannedRepMax)-rep ceiling at RPE \(String(format: "%.1f", rpe))/10. Add \(String(format: "%.1f", jump)) lb and drop back to \(reps) reps."
                }
            } else {
                reason = "Last set was near failure at RPE \(String(format: "%.1f", rpe))/10. Repeat this weight until it feels like RPE 8 before adding load."
            }
        }

        if let rf = recoveryFactor, rf < 0.7, weight > 0 {
            weight = roundedToPlate(weight * max(rf, 0.85))
            caution = "Recovery is below baseline (sleep and HRV are down). Intensity trimmed. Keep technique crisp and stop one rep early."
        }

        let maxJump = last.weightLB * 0.05
        if last.weightLB > 0 && weight > last.weightLB + maxJump + 0.01 {
            weight = roundedToPlate(last.weightLB + maxJump)
        }

        return RampSuggestion(
            exerciseName: name,
            targetWeightLB: weight,
            targetSets: max(plannedSets, 1),
            targetReps: reps,
            reason: reason,
            caution: caution,
            hasHistory: true
        )
    }
}
