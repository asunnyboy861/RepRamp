import Foundation
import StoreKit

enum BYOProvider: String, CaseIterable, Codable, Identifiable {
    case openai, anthropic, gemini, deepseek, glm, custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "GPT"
        case .anthropic: return "Claude"
        case .gemini: return "Gemini"
        case .deepseek: return "DeepSeek"
        case .glm: return "GLM (Z.ai)"
        case .custom: return "Custom"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1/chat/completions"
        case .deepseek: return "https://api.deepseek.com/chat/completions"
        case .glm: return "https://api.z.ai/api/paas/v4/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        case .anthropic: return "https://api.anthropic.com/v1/messages"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .anthropic: return "claude-sonnet-4-5"
        case .gemini: return "gemini-2.5-flash"
        case .deepseek: return "deepseek-chat"
        case .glm: return "glm-5.3-flash"
        case .custom: return ""
        }
    }

    var supportsVision: Bool { self != .deepseek }

    var isNativeAnthropic: Bool { self == .anthropic }
}

struct BYOConfig: Codable, Equatable {
    var provider: BYOProvider
    var apiKey: String
    var model: String
    var baseURL: String
}

struct BYOEngine: AIEngine {
    let config: BYOConfig

    func complete(prompt: String, imageJPEG: Data?) async throws -> String {
        if imageJPEG != nil && !config.provider.supportsVision {
            throw AIError.visionUnsupported
        }
        if config.provider.isNativeAnthropic {
            return try await anthropicCall(prompt: prompt, imageJPEG: imageJPEG)
        }
        return try await openAICompatibleCall(prompt: prompt, imageJPEG: imageJPEG)
    }

    private func openAICompatibleCall(prompt: String, imageJPEG: Data?) async throws -> String {
        guard !config.apiKey.isEmpty, let url = URL(string: config.baseURL), !config.baseURL.isEmpty else {
            throw AIError.provider("Add a valid base URL and API key in Settings.")
        }
        var userContent: [[String: Any]] = [["type": "text", "text": prompt]]
        if let jpeg = imageJPEG {
            userContent.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(jpeg.base64EncodedString())"]])
        }
        var payload: [String: Any] = [
            "model": config.model,
            "messages": [["role": "user", "content": userContent]],
            "temperature": 0.4
        ]
        payload["response_format"] = ["type": "json_object"]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 120
        let data = try await send(request)
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidOutput
        }
        return content
    }

    private func anthropicCall(prompt: String, imageJPEG: Data?) async throws -> String {
        guard !config.apiKey.isEmpty,
              let url = URL(string: config.baseURL.isEmpty ? BYOProvider.anthropic.defaultBaseURL : config.baseURL) else {
            throw AIError.provider("Add a valid Claude API endpoint and key in Settings.")
        }
        var content: [[String: Any]] = [["type": "text", "text": prompt]]
        if let jpeg = imageJPEG {
            content.insert(["type": "image", "source": [
                "type": "base64",
                "media_type": "image/jpeg",
                "data": jpeg.base64EncodedString()
            ]], at: 0)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": config.model,
            "max_tokens": 8192,
            "messages": [["role": "user", "content": content]]
        ])
        request.timeoutInterval = 120
        let data = try await send(request)
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let blocks = obj["content"] as? [[String: Any]],
              let text = blocks.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
            throw AIError.invalidOutput
        }
        return text
    }

    private func send(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AIError.network }
            switch http.statusCode {
            case 200...299:
                return data
            case 401, 403:
                throw AIError.provider("The provider rejected this API key (HTTP \(http.statusCode)).")
            case 404:
                throw AIError.provider("Endpoint or model not found (HTTP 404). Check the base URL and model name.")
            case 429:
                throw AIError.rateLimited
            default:
                let body = String(data: data, encoding: .utf8)?.prefix(160) ?? ""
                throw AIError.provider("Provider error \(http.statusCode). \(body)")
            }
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.network
        }
    }
}
