import Foundation
import StoreKit

struct GLMProxyEngine: AIEngine {
    static let appId = "repramp"
    static let primaryURL = URL(string: "https://cramjam-api.calcs.top")!
    static let backupURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!
    private static let userIdService = "com.zzoutuo.RepRamp"
    private static let userIdAccount = "glmUserId"

    static var devKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static var isConfigured: Bool { devKey != nil }

    static func userId() -> String {
        if let existing = KeychainHelper.readString(service: userIdService, account: userIdAccount) {
            return existing
        }
        let generated = UUID().uuidString
        KeychainHelper.saveString(generated, service: userIdService, account: userIdAccount)
        return generated
    }

    func complete(prompt: String, imageJPEG: Data?) async throws -> String {
        var userContent: [[String: Any]] = [["type": "text", "text": prompt]]
        if let jpeg = imageJPEG {
            userContent.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(jpeg.base64EncodedString())"]])
        }
        let payload: [String: Any] = [
            "model": "glm-5.3-flash",
            "messages": [["role": "user", "content": userContent]],
            "thinking": ["level": "low"],
            "max_tokens": imageJPEG == nil ? 4096 : 8192,
            "temperature": 0.4,
            "response_format": ["type": "json_object"]
        ]
        var body: [String: Any] = [
            "appId": Self.appId,
            "userId": Self.userId(),
            "payload": payload
        ]
        if let jws = await StoreKitManager.shared.entitlementJWS() {
            body["appTransaction"] = jws
        } else if let devKey = Self.devKey {
            body["devKey"] = devKey
        } else {
            throw AIError.proRequired
        }

        do {
            return try await send(body: body, to: Self.primaryURL)
        } catch AIError.network {
            return try await send(body: body, to: Self.backupURL)
        }
    }

    private func send(body: [String: Any], to url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.network
        }
        guard let http = response as? HTTPURLResponse else { throw AIError.network }
        switch http.statusCode {
        case 200:
            break
        case 429:
            throw AIError.rateLimited
        case 401, 403:
            throw AIError.entitlementInvalid
        case 400:
            throw AIError.invalidOutput
        default:
            throw AIError.network
        }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty else {
            throw AIError.invalidOutput
        }
        return content
    }
}
