import SwiftUI

struct ClipboardStudioMenuBarIcon: View {
    var isActive = false
    var isAlerting = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "list.clipboard")
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(isActive ? 1 : 0.92))
                .frame(width: 18, height: 14)

            if isActive {
                Circle()
                    .fill(Color.primary.opacity(isAlerting ? 1 : 0.96))
                    .frame(width: isAlerting ? 5.5 : 4.5, height: isAlerting ? 5.5 : 4.5)
                    .offset(x: 1, y: -1)
            }
        }
        .padding(.horizontal, 1)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if isAlerting {
            return "\(ContextAssemblyBrand.appName) clipboard fallback ready"
        }
        if isActive {
            return "\(ContextAssemblyBrand.appName) ready"
        }
        return ContextAssemblyBrand.appName
    }
}
