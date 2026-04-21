import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct SVGTo3DForgeSnapshot {
    let preset: String
    let format: String
    let depth: Double
    let bevel: Double
    let size: Double
    let sourcePath: String
    let outputPath: String
    let status: String
}

struct SVGTo3DForgeDetailView: View {
    let snapshot: SVGTo3DForgeSnapshot
    let sections: [SkillSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            snapshotCard
            sectionsCard
            settingsCard
            statusCard
        }
    }

    private var snapshotCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snapshot.preset)
                    .font(.headline)
                    .foregroundStyle(SVGTo3DForgeTheme.textPrimary)
                Spacer(minLength: 0)
                Text(snapshot.format.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SVGTo3DForgeTheme.textSecondary)
            }

            Text(snapshot.sourcePath)
                .font(.caption)
                .foregroundStyle(SVGTo3DForgeTheme.textSecondary)

            Text(snapshot.outputPath)
                .font(.caption)
                .foregroundStyle(SVGTo3DForgeTheme.textSecondary)
        }
        .padding(14)
        .background(SVGTo3DForgeTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SVGTo3DForgeTheme.border, lineWidth: 1)
        )
    }

    private var sectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(SVGTo3DForgeTheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(SVGTo3DForgeTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(SVGTo3DForgeTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SVGTo3DForgeTheme.border, lineWidth: 1)
        )
    }

    private var settingsCard: some View {
        HStack(spacing: 10) {
            MetricPill(label: "Depth", value: String(format: "%.1f mm", snapshot.depth))
            MetricPill(label: "Bevel", value: String(format: "%.2f mm", snapshot.bevel))
            MetricPill(label: "Size", value: String(format: "%.0f mm", snapshot.size))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Export status")
                .font(.headline)
                .foregroundStyle(SVGTo3DForgeTheme.textPrimary)
            Text(snapshot.status)
                .font(.subheadline)
                .foregroundStyle(SVGTo3DForgeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SVGTo3DForgeTheme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SVGTo3DForgeTheme.accent.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SVGTo3DForgeTheme.textSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(SVGTo3DForgeTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension SVGTo3DForgeSnapshot {
    static let preview = SVGTo3DForgeSnapshot(
        preset: "Badge preset",
        format: "stl",
        depth: 3.2,
        bevel: 0.25,
        size: 82,
        sourcePath: "~/Desktop/badge.svg",
        outputPath: "~/Desktop/badge.stl",
        status: "Blender ready. Export the extruded badge as STL for the slicer, or switch to GLB for a lightweight viewer asset."
    )
}

extension SVGTo3DForgeDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(
                title: "SVG scaffold",
                body: "Start with a deterministic badge, coin, plaque, or keycap face so the vector source stays editable before extrusion."
            ),
            SkillSection(
                title: "Extrusion controls",
                body: "Keep format, depth, bevel, and overall size in one compact stack so the user can change the export profile without opening a full modeling app."
            ),
            SkillSection(
                title: "3D handoff",
                body: "Lead with Blender readiness, output path, and a reveal action because the point is to hand the model into printing, viewing, or another DCC tool quickly."
            )
        ]
    }
}
