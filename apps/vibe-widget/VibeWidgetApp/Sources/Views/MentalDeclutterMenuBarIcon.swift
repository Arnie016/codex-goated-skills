import SwiftUI

struct MentalDeclutterMenuBarIcon: View {
    var isActive = false

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            let unit = min(size.width, size.height)
            let strokeWidth = max(1.35, unit * 0.12)
            let strokeStyle = StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
            let haloColor = Color.primary.opacity(isActive ? 1 : 0.82)
            let lineColor = Color.primary.opacity(isActive ? 0.98 : 0.64)
            let dotColor = Color.primary.opacity(isActive ? 1 : 0.45)

            let haloCenter = CGPoint(x: size.width * 0.47, y: size.height * 0.5)
            let haloRadius = unit * 0.42

            var halo = Path()
            halo.addArc(
                center: haloCenter,
                radius: haloRadius,
                startAngle: .degrees(isActive ? -20 : -14),
                endAngle: .degrees(isActive ? 286 : 248),
                clockwise: false
            )
            context.stroke(halo, with: .color(haloColor), style: strokeStyle)

            let lineFractions: [(y: CGFloat, halfWidth: CGFloat)] = [
                (0.34, 0.12),
                (0.53, 0.19),
                (0.72, 0.25)
            ]

            for line in lineFractions {
                let center = CGPoint(x: size.width * 0.5, y: size.height * line.y)
                var path = Path()
                path.move(to: CGPoint(x: center.x - size.width * line.halfWidth, y: center.y))
                path.addLine(to: CGPoint(x: center.x + size.width * line.halfWidth, y: center.y))
                context.stroke(path, with: .color(lineColor), style: strokeStyle)
            }

            var focusDot = Path()
            focusDot.addEllipse(
                in: CGRect(
                    x: size.width * 0.69,
                    y: size.height * 0.14,
                    width: unit * 0.16,
                    height: unit * 0.16
                )
            )
            context.fill(focusDot, with: .color(dotColor))
        }
        .frame(width: 18, height: 14)
        .padding(.horizontal, 1)
        .accessibilityLabel(isActive ? "Mind declutter active" : "Mind declutter inactive")
    }
}
