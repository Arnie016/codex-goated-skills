import Foundation
import VibeWidgetCore

struct AICommandService {
    private let keychain = KeychainSecretStore()

    func plan(for text: String, settings: AppSettings) async -> AICommandPlan {
        if let remote = try? await remotePlan(for: text, settings: settings) {
            return remote
        }
        return FallbackIntentParser.parse(text, defaultRoom: settings.defaultRoomName)
    }

    private func remotePlan(for text: String, settings: AppSettings) async throws -> AICommandPlan {
        let apiKey = try keychain.read(service: settings.openAIKeyServiceName)
        guard !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let schemaPrompt = """
        Return only minified JSON with keys:
        originalText:string,
        room:string|null,
        light:{action:"none"|"dim"|"off"|"on"|"scene",brightnessPercent:number|null,sceneName:string|null},
        music:{action:"none"|"play"|"recommend"|"rain"|"chill",query:string|null,autoplay:boolean},
        seedArtists:string[],
        excludedArtists:string[],
        moodTags:string[],
        confidence:number,
        needsConfirmation:boolean.
        The room should default to \(settings.defaultRoomName) if the user references lights without naming a room.
        """

        let payload: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": [
                [
                    "role": "system",
                    "content": [["type": "input_text", "text": schemaPrompt]]
                ],
                [
                    "role": "user",
                    "content": [["type": "input_text", "text": text]]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data)
        let textOutput = extractText(from: json) ?? ""
        let jsonString = firstJSONObject(in: textOutput) ?? textOutput
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        return try JSONDecoder().decode(AICommandPlan.self, from: jsonData)
    }

    private func extractText(from value: Any) -> String? {
        if let string = value as? String, string.contains("{") {
            return string
        }
        if let dictionary = value as? [String: Any] {
            if let outputText = dictionary["output_text"] as? String {
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

    private func firstJSONObject(in string: String) -> String? {
        guard let start = string.firstIndex(of: "{"), let end = string.lastIndex(of: "}") else {
            return nil
        }
        return String(string[start...end])
    }
}
