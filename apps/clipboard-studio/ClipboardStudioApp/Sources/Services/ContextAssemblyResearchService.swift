import Foundation

struct ContextAssemblyResearchService {
    enum ServiceError: LocalizedError {
        case invalidResponse
        case emptyOutput

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "OpenAI returned an unreadable research response."
            case .emptyOutput:
                return "The research agent did not return any text."
            }
        }
    }

    private let model = "gpt-4.1-mini"

    func research(
        focus: FocusSnapshot,
        objective: String,
        apiKey: String
    ) async throws -> String {
        let instructions = """
        You are the built-in research agent for a macOS context assembly tool.
        Produce a compact research note that is immediately useful inside an AI prompt or work brief.
        If the current focus suggests a live topic, website, company, place, product, or current event, use web search.
        Keep the response tight and practical.

        Format:
        ## Quick Read
        2-3 short bullets.

        ## Useful Angles
        2-4 bullets that help the user continue the task.

        ## Suggested Ask
        One short prompt they can send to an AI next.
        """

        let input = """
        Objective:
        \(objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "none" : objective)

        Current focus:
        \(focus.assemblyText)
        """

        var payload: [String: Any] = [
            "model": model,
            "instructions": instructions,
            "input": input,
            "tools": [
                ["type": "web_search"]
            ],
            "tool_choice": "auto",
            "max_tool_calls": 2,
            "max_output_tokens": 500
        ]

        payload["include"] = ["web_search_call.action.sources"]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data)
        let textOutput = extractText(from: json)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !textOutput.isEmpty else {
            throw ServiceError.emptyOutput
        }

        let sources = extractSources(from: json)
        guard !sources.isEmpty else {
            return textOutput
        }

        let sourceLines = sources.map { "- \($0.title): \($0.url)" }.joined(separator: "\n")
        return "\(textOutput)\n\n## Sources\n\(sourceLines)"
    }

    private func extractText(from value: Any) -> String? {
        if let string = value as? String,
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return string
        }

        if let dictionary = value as? [String: Any] {
            if let outputText = dictionary["output_text"] as? String,
               !outputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return outputText
            }

            for nested in dictionary.values {
                if let match = extractText(from: nested) {
                    return match
                }
            }
        }

        if let array = value as? [Any] {
            for item in array {
                if let match = extractText(from: item) {
                    return match
                }
            }
        }

        return nil
    }

    private func extractSources(from value: Any) -> [(title: String, url: String)] {
        var results: [(title: String, url: String)] = []
        collectSources(from: value, into: &results)

        var seen = Set<String>()
        return results.filter { source in
            seen.insert(source.url).inserted
        }
    }

    private func collectSources(from value: Any, into results: inout [(title: String, url: String)]) {
        if let dictionary = value as? [String: Any] {
            if let title = dictionary["title"] as? String,
               let url = dictionary["url"] as? String,
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                results.append((title, url))
            }

            for nested in dictionary.values {
                collectSources(from: nested, into: &results)
            }
        } else if let array = value as? [Any] {
            for item in array {
                collectSources(from: item, into: &results)
            }
        }
    }
}
