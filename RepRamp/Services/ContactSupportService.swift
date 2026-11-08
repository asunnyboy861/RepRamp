import Foundation

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

enum ContactSupportService {
    static let endpoint = URL(string: "https://msg.calcs.top/api/feedback")!

    static func submit(_ feedback: FeedbackRequest) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(feedback)
        request.timeoutInterval = 30
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw FeedbackError.network }
            guard http.statusCode == 200 else {
                if let decoded = try? JSONDecoder().decode(FeedbackErrorBody.self, from: data), let message = decoded.error {
                    throw FeedbackError.server(message)
                }
                throw FeedbackError.server("The server responded with status \(http.statusCode).")
            }
            let decoded = try? JSONDecoder().decode(FeedbackSuccess.self, from: data)
            if decoded?.success == false {
                throw FeedbackError.server("The server rejected the message.")
            }
        } catch let error as FeedbackError {
            throw error
        } catch {
            throw FeedbackError.network
        }
    }
}

struct FeedbackSuccess: Codable {
    let success: Bool?
    let id: Int?
}

struct FeedbackErrorBody: Codable {
    let error: String?
}

enum FeedbackError: LocalizedError {
    case network
    case server(String)

    var errorDescription: String? {
        switch self {
        case .network: return "Something went wrong. Please try again."
        case .server(let message): return message
        }
    }
}
