import Foundation
import SwiftUI

@MainActor
final class AIGateway: ObservableObject {
    static let shared = AIGateway()

    @Published var byoConfig: BYOConfig?
    @Published var lastError: String?

    private let service = "com.zzoutuo.RepRamp.byo"
    private let account = "config"

    private init() {
        loadConfig()
    }

    var appleAvailable: Bool { AppleIntelligenceEngine.isAvailable }
    var hasBYO: Bool { byoConfig != nil }
    var cloudEntitled: Bool { StoreKitManager.shared.isPro }
    var canUseAnyTextAI: Bool { hasBYO || appleAvailable || cloudEntitled }
    var canUseVisionAI: Bool { (byoConfig?.provider.supportsVision == true) || cloudEntitled }

    var statusBadge: String {
        if let byo = byoConfig {
            return "BYO: \(byo.provider.displayName) · \(byo.model)"
        }
        if appleAvailable {
            return "Apple AI (on-device)"
        }
        if cloudEntitled {
            return "GLM (official)"
        }
        return "No AI engine configured"
    }

    var availabilityMessage: String {
        if canUseAnyTextAI { return "AI plan drafting is available." }
        return "Apple Intelligence needs iOS 26 and a supported device. Add your own API key in Settings or unlock Pro to use cloud AI."
    }

    func loadConfig() {
        guard let data = KeychainHelper.read(service: service, account: account),
              let config = try? JSONDecoder().decode(BYOConfig.self, from: data) else {
            byoConfig = nil
            return
        }
        byoConfig = config
    }

    func saveConfig(_ config: BYOConfig) {
        if let data = try? JSONEncoder().encode(config) {
            KeychainHelper.save(data, service: service, account: account)
            byoConfig = config
        }
    }

    func clearConfig() {
        KeychainHelper.delete(service: service, account: account)
        byoConfig = nil
    }

    func testConnection(_ config: BYOConfig) async throws -> String {
        let engine = BYOEngine(config: config)
        let start = Date()
        let response = try await engine.complete(prompt: "Reply with {\"ok\":true} only.", imageJPEG: nil)
        let ms = Int(Date().timeIntervalSince(start) * 1000)
        return "Connected · \(config.model) · \(ms) ms · \(response.prefix(40))"
    }

    func generatePlan(_ answers: PlanQuestionnaire) async throws -> PlanDraft {
        let prompt = """
        You are an expert strength coach. Design a weekly training plan.
        Goal: \(answers.goal)
        Experience: \(answers.experience)
        Training location: \(answers.location)
        Days per week: \(answers.daysPerWeek)

        Return ONLY a JSON object with this exact shape:
        {"name":"plan name","goal":"short goal","sessions":[{"dayName":"Day name","items":[{"exerciseName":"Barbell Bench Press - Medium Grip","targetSets":3,"targetRepsMin":8,"targetRepsMax":12,"restSeconds":90}]}]}

        Rules: exactly \(answers.daysPerWeek) sessions. 4-6 exercises per session. Compound lifts first. Use common English exercise names. targetSets 2-5, targetRepsMin 4-20, targetRepsMax >= targetRepsMin, restSeconds 45-180. No supersets. No commentary outside JSON.
        """
        let raw = try await runText(prompt: prompt)
        return try AIResponseValidator.planDraft(from: raw)
    }

    func importScreenshot(image: Data) async throws -> PlanDraft {
        let prompt = """
        Read the workout plan shown in this screenshot and convert it into a structured weekly plan.
        Return ONLY a JSON object with this exact shape:
        {"name":"plan name","goal":"short goal","sessions":[{"dayName":"Day name","items":[{"exerciseName":"Bench Press","targetSets":3,"targetRepsMin":8,"targetRepsMax":12,"restSeconds":90}]}]}
        Keep the original day order. Use common English exercise names. targetSets 1-6, targetRepsMin 1-30, restSeconds 30-300. No commentary outside JSON.
        """
        let engine = try visionEngine()
        let raw = try await engine.complete(prompt: prompt, imageJPEG: image)
        return try AIResponseValidator.planDraft(from: raw)
    }

    func analyzeBodyScan(image: Data) async throws -> BodyScanResult {
        let prompt = """
        You are a physique coach. Analyze this progress photo for muscle balance and symmetry. Be conservative and only comment on what is visible.
        Return ONLY a JSON object:
        {"balance":[{"muscle":"Chest","score":7},{"muscle":"Back","score":5},{"muscle":"Shoulders","score":6},{"muscle":"Quads","score":7},{"muscle":"Hamstrings","score":5},{"muscle":"Core","score":6}],"priorities":["Add one weekly back-focused session","Keep pushing progressive overload on pressing","Include rear delt work twice a week"],"summary":"Short paragraph."}
        Scores are 1-10. Provide 5-10 muscles from: Chest, Back, Shoulders, Biceps, Triceps, Core, Quads, Hamstrings, Glutes, Calves. Priorities: 3 short actionable coaching notes. No commentary outside JSON.
        """
        let engine = try visionEngine()
        let raw = try await engine.complete(prompt: prompt, imageJPEG: image)
        return try AIResponseValidator.bodyScan(from: raw)
    }

    func runText(prompt: String) async throws -> String {
        if let config = byoConfig {
            return try await BYOEngine(config: config).complete(prompt: prompt, imageJPEG: nil)
        }
        if AppleIntelligenceEngine.isAvailable {
            do {
                return try await AppleIntelligenceEngine().complete(prompt: prompt, imageJPEG: nil)
            } catch {
                if cloudEntitled {
                    return try await GLMProxyEngine().complete(prompt: prompt, imageJPEG: nil)
                }
                throw error
            }
        }
        if cloudEntitled {
            return try await GLMProxyEngine().complete(prompt: prompt, imageJPEG: nil)
        }
        throw AIError.engineUnavailable
    }

    private func visionEngine() throws -> AIEngine {
        if let config = byoConfig, config.provider.supportsVision {
            return BYOEngine(config: config)
        }
        if let config = byoConfig, !config.provider.supportsVision {
            throw AIError.visionUnsupported
        }
        if cloudEntitled {
            return GLMProxyEngine()
        }
        throw AIError.proRequired
    }
}
