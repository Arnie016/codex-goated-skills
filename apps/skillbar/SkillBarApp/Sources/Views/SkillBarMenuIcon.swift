import AppKit
import SwiftUI

struct SkillBarMenuIcon: View {
    let isBusy: Bool
    let installedCount: Int
    let entry: PinnedMenuBarEntrySnapshot?

    var body: some View {
        ZStack {
            menuBarGlyph

            if isBusy {
                statusBadge(fill: Color(red: 0.97, green: 0.74, blue: 0.36), diameter: 6)
                    .overlay(alignment: .center) {
                        Circle()
                            .fill(Color.black.opacity(0.28))
                            .frame(width: 2.5, height: 2.5)
                    }
                    .offset(x: 3, y: -3)
            }

            if installedCount > 0 {
                statusBadge(fill: Color.white, diameter: 5)
                    .offset(x: 3, y: 3)
            }
        }
        .frame(width: 18, height: 16)
    }

    @ViewBuilder
    private var menuBarGlyph: some View {
        if let image = menuBarImage {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
        } else {
            Image(systemName: isBusy ? "square.stack.3d.up.fill" : fallbackSymbolName)
                .font(.system(size: 14, weight: .semibold))
        }
    }

    private var fallbackSymbolName: String {
        entry?.category.symbolName ?? "square.stack.3d.up"
    }

    private var menuBarImage: NSImage? {
        guard let entry else { return nil }
        for path in [entry.iconSmallPath, entry.iconLargePath].compactMap({ $0 }) {
            if let image = NSImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }

    private func statusBadge(fill: Color, diameter: CGFloat) -> some View {
        Circle()
            .fill(fill)
            .frame(width: diameter, height: diameter)
            .overlay(
                Circle()
                    .strokeBorder(Color.black.opacity(0.35), lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 1.2, y: 0.4)
    }
}
