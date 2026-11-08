import Foundation

enum AIResponseValidator {
    static func cleaned(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            text = String(text[start...end])
        }
        return text
    }

    static func planDraft(from raw: String) throws -> PlanDraft {
        guard let data = cleaned(raw).data(using: .utf8),
              let draft = try? JSONDecoder().decode(PlanDraft.self, from: data) else {
            throw AIError.invalidOutput
        }
        var sessions: [PlanSessionDraft] = []
        for session in draft.sessions.prefix(7) {
            var items: [PlanItemDraft] = []
            for item in session.items.prefix(10) {
                let name = item.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, name.count <= 60 else { continue }
                let sets = min(6, max(1, item.targetSets))
                let repsMin = min(30, max(1, item.targetRepsMin))
                let repsMax = min(40, max(repsMin, item.targetRepsMax))
                let rest = min(300, max(30, item.restSeconds))
                items.append(PlanItemDraft(exerciseName: name, targetSets: sets, targetRepsMin: repsMin, targetRepsMax: repsMax, restSeconds: rest))
            }
            guard !items.isEmpty else { continue }
            let dayName = session.dayName.trimmingCharacters(in: .whitespacesAndNewlines)
            sessions.append(PlanSessionDraft(dayName: dayName.isEmpty ? "Day \(sessions.count + 1)" : String(dayName.prefix(40)), items: items))
        }
        guard !sessions.isEmpty else { throw AIError.invalidOutput }
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = draft.goal.trimmingCharacters(in: .whitespacesAndNewlines)
        return PlanDraft(
            name: String((name.isEmpty ? "AI Plan" : name).prefix(50)),
            goal: String((goal.isEmpty ? "General Health" : goal).prefix(30)),
            sessions: sessions
        )
    }

    static func bodyScan(from raw: String) throws -> BodyScanResult {
        guard let data = cleaned(raw).data(using: .utf8),
              let result = try? JSONDecoder().decode(BodyScanResult.self, from: data) else {
            throw AIError.invalidOutput
        }
        let balance = result.balance.prefix(12).map { item in
            MuscleScore(muscle: String(item.muscle.prefix(24)), score: min(10, max(1, item.score)))
        }
        guard balance.count >= 3 else { throw AIError.invalidOutput }
        let priorities = result.priorities.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.prefix(4)
        guard !priorities.isEmpty else { throw AIError.invalidOutput }
        return BodyScanResult(balance: Array(balance), priorities: Array(priorities), summary: result.summary)
    }
}
