import SwiftUI

struct SVGTo3DForgeMenuBarView: View {
    private let detailLines: [String] = [
        "Scaffold simple badge, coin, plaque, or keycap SVGs locally.",
        "Extrude the imported vector through Blender into STL, OBJ, or GLB.",
        "Keep the utility focused on source SVG, extrusion settings, and export handoff."
    ]

    private let snapshot = SVGTo3DForgeSnapshot.preview
    private let sections = SVGTo3DForgeDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            SVGTo3DForgeDetailView(snapshot: snapshot, sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 388)
        .background(SVGTo3DForgeTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(SVGTo3DForgeTheme.accent)
                Image(systemName: "cube.transparent")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("SVG To 3D Forge")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SVGTo3DForgeTheme.textPrimary)
                Text("A menu-bar forge for scaffolded SVG assets, extrusion settings, and local model export.")
                    .font(.subheadline)
                    .foregroundStyle(SVGTo3DForgeTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Mac OS")
            TagPill(text: "Blender export")
            TagPill(text: "SVG-first")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(SVGTo3DForgeTheme.textSecondary)
            }
        }
        .padding(12)
        .background(SVGTo3DForgeTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SVGTo3DForgeTheme.border, lineWidth: 1)
        )
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Scaffold SVG") { }
                .buttonStyle(.borderedProminent)
            Button("Export STL") { }
                .buttonStyle(.bordered)
            Button("Reveal model") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(SVGTo3DForgeTheme.textPrimary.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule(style: .continuous))
    }
}
