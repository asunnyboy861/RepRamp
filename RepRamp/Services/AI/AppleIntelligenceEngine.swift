import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct AppleIntelligenceEngine: AIEngine {
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            default:
                return false
            }
            #else
            return false
            #endif
        }
        return false
        #endif
    }

    func complete(prompt: String, imageJPEG: Data?) async throws -> String {
        guard imageJPEG == nil else { throw AIError.visionUnsupported }
        guard #available(iOS 26.0, *) else { throw AIError.engineUnavailable }
        #if canImport(FoundationModels)
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content
        #else
        throw AIError.engineUnavailable
        #endif
    }
}
