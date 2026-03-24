import SwiftUI

struct WorkspacePanelView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            VibeBackdrop(secondaryOnly: true)

            VStack(alignment: .leading, spacing: 20) {
                header

                Group {
                    switch model.activePanelRoute {
                    case .vibe:
                        VibePanelView(model: model)
                    case .paperBridge:
                        PaperBridgeView(model: model)
                    case .context:
                        ContextStudioView(model: model)
                    }
                }
            }
            .padding(26)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.activePanelRoute.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text(model.activePanelRoute.subtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                ForEach(WorkspacePanelRoute.allCases) { route in
                    PanelRouteChip(route: route, isActive: route == model.activePanelRoute) {
                        model.activePanelRoute = route
                    }
                }
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }
}
