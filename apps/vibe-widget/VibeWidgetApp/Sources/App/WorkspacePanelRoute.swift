import Foundation

enum WorkspacePanelRoute: String, CaseIterable, Identifiable {
    case vibe
    case paperBridge
    case context

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vibe:
            return "AI Vibe Panel"
        case .paperBridge:
            return "Paper Bridge"
        case .context:
            return "Context Studio"
        }
    }

    var subtitle: String {
        switch self {
        case .vibe:
            return "Type or speak a command, then let the parser turn it into lighting plus music actions."
        case .paperBridge:
            return "Dispatch GitHub Actions prompts, sync LaTeX to Overleaf, and pull down the latest PDF artifact."
        case .context:
            return "Drop folders, docs, and code to estimate tokens instantly and prep a local retrieval pack."
        }
    }

    var shortTitle: String {
        switch self {
        case .vibe:
            return "Vibe"
        case .paperBridge:
            return "Paper"
        case .context:
            return "Context"
        }
    }

    var systemImage: String {
        switch self {
        case .vibe:
            return "waveform.and.sparkles"
        case .paperBridge:
            return "doc.text.fill"
        case .context:
            return "shippingbox.and.arrow.trianglehead.counterclockwise"
        }
    }
}
