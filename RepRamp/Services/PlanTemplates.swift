import Foundation

struct PlanQuestionnaire {
    var goal: String
    var experience: String
    var location: String
    var daysPerWeek: Int
}

enum PlanTemplates {
    static let goals = ["Build Muscle", "Get Stronger", "Lose Fat", "General Health"]
    static let experienceLevels = ["Beginner", "Intermediate", "Advanced"]
    static let locations = ["Gym", "Home"]
    static let dayOptions = [3, 4, 5, 6]

    static func makePlan(from answers: PlanQuestionnaire) -> [PlanSession] {
        let gym = answers.location == "Gym"
        let experienceOffset = answers.experience == "Beginner" ? -1 : (answers.experience == "Advanced" ? 0 : 0)
        let strength = answers.goal == "Get Stronger"

        func sets(_ base: Int) -> Int { max(2, base + experienceOffset) }
        func reps(_ hypertrophy: Bool) -> (Int, Int, Int) {
            if strength { return (4, 4, 6) }
            if hypertrophy { return (3, 8, 12) }
            return (3, 12, 15)
        }
        let rest = strength ? 150 : (answers.goal == "Lose Fat" ? 60 : 90)

        func item(_ name: String, _ baseSets: Int, rest overrideRest: Int? = nil) -> PlanItem {
            let range = reps(answers.goal == "Build Muscle")
            return PlanItem(exerciseName: name, targetSets: sets(baseSets), targetRepsMin: range.0, targetRepsMax: range.1, restSeconds: overrideRest ?? rest)
        }
        let ab = answers.goal == "Lose Fat" ? "Plank" : "Crunches"

        let squat = gym ? "Barbell Squat" : "Bodyweight Squat"
        let hinge = gym ? "Barbell Deadlift" : "Romanian Deadlift"
        let horizontalPush = gym ? "Barbell Bench Press - Medium Grip" : "Pushups"
        let horizontalPull = gym ? "Bent Over Barbell Row" : "One-Arm Dumbbell Row"
        let verticalPush = gym ? "Dumbbell Shoulder Press" : "Dumbbell Shoulder Press"
        let verticalPull = gym ? "Wide-Grip Lat Pulldown" : "Chin-Up"
        let legsAccessory = gym ? "Leg Press" : "Dumbbell Lunges"
        let hamstring = gym ? "Lying Leg Curls" : "Romanian Deadlift"
        let quad = gym ? "Leg Extensions" : "Goblet Squat"
        let chestAccessory = gym ? "Incline Dumbbell Press" : "Dumbbell Bench Press"
        let delts = gym ? "Side Lateral Raise" : "Side Lateral Raise"
        let biceps = gym ? "Barbell Curl" : "Hammer Curls"
        let triceps = gym ? "Triceps Pushdown" : "Dips - Triceps Version"
        let calves = gym ? "Standing Calf Raises" : "Calf Raises - With Bands"
        let glutes = gym ? "Barbell Hip Thrust" : "Barbell Hip Thrust"
        let rearDelts = "Face Pull"

        switch answers.daysPerWeek {
        case 3:
            return [
                PlanSession(dayName: "Full Body A", items: [item(squat, 3), item(horizontalPush, 3), item(horizontalPull, 3), item(ab, 3)]),
                PlanSession(dayName: "Full Body B", items: [item(hinge, 2), item(verticalPush, 3), item(verticalPull, 3), item(calves, 3)]),
                PlanSession(dayName: "Full Body C", items: [item(legsAccessory, 3), item(chestAccessory, 3), item(horizontalPull, 3), item(biceps, 2), item(triceps, 2)])
            ]
        case 4:
            return [
                PlanSession(dayName: "Upper A", items: [item(horizontalPush, 4), item(horizontalPull, 4), item(verticalPush, 3), item(verticalPull, 3), item(triceps, 2)]),
                PlanSession(dayName: "Lower A", items: [item(squat, 4), item(hamstring, 3), item(quad, 3), item(calves, 3), item(ab, 3)]),
                PlanSession(dayName: "Upper B", items: [item(chestAccessory, 3), item(horizontalPull, 3), item(delts, 3), item(rearDelts, 3), item(biceps, 2)]),
                PlanSession(dayName: "Lower B", items: [item(hinge, 3), item(glutes, 3), item(legsAccessory, 3), item(hamstring, 2), item(calves, 3)])
            ]
        case 5:
            return [
                PlanSession(dayName: "Push", items: [item(horizontalPush, 4), item(verticalPush, 3), item(chestAccessory, 3), item(delts, 3), item(triceps, 2)]),
                PlanSession(dayName: "Pull", items: [item(horizontalPull, 4), item(verticalPull, 3), item(rearDelts, 3), item(biceps, 2), item(hinge, 2)]),
                PlanSession(dayName: "Legs", items: [item(squat, 4), item(hamstring, 3), item(quad, 3), item(calves, 3), item(ab, 3)]),
                PlanSession(dayName: "Upper", items: [item(chestAccessory, 3), item(horizontalPull, 3), item(delts, 3), item(triceps, 2), item(biceps, 2)]),
                PlanSession(dayName: "Lower", items: [item(hinge, 3), item(glutes, 3), item(legsAccessory, 3), item(calves, 3)])
            ]
        default:
            return [
                PlanSession(dayName: "Push A", items: [item(horizontalPush, 4), item(verticalPush, 3), item(delts, 3), item(triceps, 2)]),
                PlanSession(dayName: "Pull A", items: [item(horizontalPull, 4), item(verticalPull, 3), item(rearDelts, 3), item(biceps, 2)]),
                PlanSession(dayName: "Legs A", items: [item(squat, 4), item(hamstring, 3), item(quad, 3), item(calves, 3)]),
                PlanSession(dayName: "Push B", items: [item(chestAccessory, 4), item(delts, 3), item(triceps, 2), item(ab, 3)]),
                PlanSession(dayName: "Pull B", items: [item(verticalPull, 3), item(horizontalPull, 3), item(glutes, 3), item(biceps, 2)]),
                PlanSession(dayName: "Legs B", items: [item(hinge, 3), item(legsAccessory, 3), item(hamstring, 3), item(ab, 3)])
            ]
        }
    }

    static func planName(from answers: PlanQuestionnaire) -> String {
        "\(answers.goal) • \(answers.daysPerWeek) Days"
    }
}
