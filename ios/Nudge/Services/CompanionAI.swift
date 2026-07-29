import Foundation

/// Wire-format message for the OpenAI-compatible chat endpoint.
nonisolated struct AIChatMessage: Codable {
    let role: String
    let content: String
}

nonisolated private struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { let content: String? }
        let delta: Delta?
    }
    let choices: [Choice]?
}

nonisolated enum CompanionAIError: Error {
    case badResponse(Int)
    case empty
}

/// Streaming client for the companion's real brain — Claude Opus 4.8 through
/// the Rork AI gateway. SSE parsed line-by-line; deltas land on the main actor.
final class CompanionAI {

    /// Streams a completion. `onDelta` receives raw text fragments as they
    /// arrive. Returns the full assembled text.
    func stream(
        system: String,
        messages: [AIChatMessage],
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws -> String {
        var request = URLRequest(url: URL(string: "\(AppConfig.toolkitURL)/v2/vercel/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.toolkitKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        var payloadMessages: [[String: String]] = [["role": "system", "content": system]]
        payloadMessages.append(contentsOf: messages.map { ["role": $0.role, "content": $0.content] })

        let body: [String: Any] = [
            "model": AppConfig.chatModel,
            "messages": payloadMessages,
            "stream": true,
            "temperature": 0.75,
            "max_tokens": 700,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw CompanionAIError.badResponse(http.statusCode)
        }

        var full = ""
        let decoder = JSONDecoder()
        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("data: ") else { continue }
            let json = String(trimmed.dropFirst(6))
            guard !json.isEmpty, json != "[DONE]" else { continue }
            guard let data = json.data(using: .utf8),
                  let chunk = try? decoder.decode(StreamChunk.self, from: data),
                  let delta = chunk.choices?.first?.delta?.content, !delta.isEmpty
            else { continue }
            full += delta
            await onDelta(delta)
        }
        guard !full.isEmpty else { throw CompanionAIError.empty }
        return full
    }
}
