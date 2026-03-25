import Foundation

enum ContextPackFormatter {
    static func format(objective: String, pack: ContextPack) -> String {
        let trimmedObjective = objective.trimmingCharacters(in: .whitespacesAndNewlines)
        var sections: [String] = []

        if !trimmedObjective.isEmpty {
            sections.append("## Objective\n\(trimmedObjective)")
        }

        for (index, item) in pack.items.enumerated() {
            let source = item.sourceAppName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? item.sourceAppName!
                : "Unknown Source"

            let trimmedText = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            sections.append(
                """
                ## Context \(index + 1) • \(source)
                ```
                \(trimmedText)
                ```
                """
            )
        }

        return sections
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
