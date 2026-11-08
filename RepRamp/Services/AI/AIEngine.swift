import Foundation

protocol AIEngine {
    func complete(prompt: String, imageJPEG: Data?) async throws -> String
}

enum AIError: LocalizedError {
    case rateLimited
    case entitlementInvalid
    case proRequired
    case engineUnavailable
    case visionUnsupported
    case invalidOutput
    case network
    case provider(String)

    var errorDescription: String? {
        switch self {
        case .rateLimited: return "Too many AI requests right now. Please try again in a few minutes."
        case .entitlementInvalid: return "Your subscription could not be verified. Restore purchases or subscribe to continue."
        case .proRequired: return "Cloud AI is a Pro feature. Unlock it or add your own API key in Settings."
        case .engineUnavailable: return "No AI engine is available. Add your own API key in Settings to use AI features."
        case .visionUnsupported: return "This provider cannot analyze images. Choose a vision-capable model in Settings."
        case .invalidOutput: return "The AI response could not be validated. Nothing was saved. Please try again."
        case .network: return "Network request failed. Check your connection and try again."
        case .provider(let message): return message
        }
    }
}

struct PlanItemDraft: Codable {
    var exerciseName: String
    var targetSets: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    var restSeconds: Int
}

struct PlanSessionDraft: Codable {
    var dayName: String
    var items: [PlanItemDraft]
}

struct PlanDraft: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var goal: String
    var sessions: [PlanSessionDraft]

    enum CodingKeys: String, CodingKey {
        case name, goal, sessions
    }

    init(name: String, goal: String, sessions: [PlanSessionDraft]) {
        self.name = name
        self.goal = goal
        self.sessions = sessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        name = try container.decode(String.self, forKey: .name)
        goal = try container.decode(String.self, forKey: .goal)
        sessions = try container.decode([PlanSessionDraft].self, forKey: .sessions)
    }
}

struct MuscleScore: Codable, Identifiable, Hashable {
    var id: String { muscle }
    var muscle: String
    var score: Int
}

struct BodyScanResult: Codable, Identifiable {
    var id: UUID = UUID()
    var balance: [MuscleScore]
    var priorities: [String]
    var summary: String?

    enum CodingKeys: String, CodingKey {
        case balance, priorities, summary
    }

    init(balance: [MuscleScore], priorities: [String], summary: String?) {
        self.balance = balance
        self.priorities = priorities
        self.summary = summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        balance = try container.decode([MuscleScore].self, forKey: .balance)
        priorities = try container.decode([String].self, forKey: .priorities)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
    }
}
