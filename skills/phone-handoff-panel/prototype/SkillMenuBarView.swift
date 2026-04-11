import SwiftUI

struct PhoneHandoffPanelMenuBarView: View {
    private let detailLines: [String] = [
            "Puts the phone-centric actions behind a quick Mac surface.",
            "Keeps a compact link between the desk and the device in your pocket.",
            "Feels more like a coordination tool than a gadget dashboard."
    ]

    private let sections = PhoneHandoffPanelDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            PhoneHandoffPanelDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 360)
        .background(PhoneHandoffPanelTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(PhoneHandoffPanelTheme.accent)
                Image(systemName: "iphone")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Handoff Panel")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("A connection panel that makes device switching feel deliberate.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Connectivity")
            TagPill(text: "5 stars")
            TagPill(text: "Active")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Open") { }
                .buttonStyle(.borderedProminent)
            Button("Copy prompt") { }
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
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule(style: .continuous))
    }
}
