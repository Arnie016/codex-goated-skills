import Foundation

enum ContextPackFormatter {
    static func format(objective: String, pack: ContextPack) -> String {
        let trimmedObjective = objective.trimmingCharacters(in: .whitespacesAndNewlines)
        var sections: [String] = []
        let timelineItems = pack.timelineItems
        let timelineSteps = Dictionary(uniqueKeysWithValues: timelineItems.enumerated().map { ($0.element.id, $0.offset + 1) })

        if !trimmedObjective.isEmpty {
            sections.append("## Objective\n\(trimmedObjective)")
        }

        if !timelineItems.isEmpty {
            let timelineLines = timelineItems.enumerated().map { index, item in
                "\(index + 1). \(item.sourceLabel) • \(timelineTimestampFormatter.string(from: item.capturedAt))"
            }
            sections.append("## Timeline\n" + timelineLines.joined(separator: "\n"))
        }

        for (index, item) in pack.items.enumerated() {
            let source = item.sourceLabel
            let trimmedText = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let timelineStep = timelineSteps[item.id] ?? (timelineItems.count - index)
            sections.append(
                """
                ## Context \(index + 1) • From \(source)
                Timeline Step: \(timelineStep) • Captured \(timelineTimestampFormatter.string(from: item.capturedAt))
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

    static func formatExportDocument(
        title: String,
        objective: String,
        pack: ContextPack,
        exportedAt: Date = Date()
    ) -> String {
        let exportedString = exportTimestampFormatter.string(from: exportedAt)
        let sources = Array(
            NSOrderedSet(
                array: pack.items.compactMap { item in
                    let source = item.sourceAppName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    return source.isEmpty ? nil : source
                }
            )
        ) as? [String] ?? []

        var sections: [String] = [
            "# \(title)",
            "Exported from \(ContextAssemblyBrand.appName) on \(exportedString)."
        ]

        if !sources.isEmpty {
            sections.append("Sources: \(sources.joined(separator: ", "))")
        }

        let promptBody = format(objective: objective, pack: pack)
        if !promptBody.isEmpty {
            sections.append(promptBody)
        }

        return sections
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let exportTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let timelineTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
