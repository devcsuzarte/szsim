//
//  LogoMark.swift
//  SZSIM
//

import SwiftUI

/// The "Z route" mark: a blue squircle with a white route-shaped "Z",
/// an origin node (white ring) and a destination node (orange dot).
struct LogoMark: View {
    var size: CGFloat
    var cornerStyle: Bool = true

    private let blue = Color(red: 0.184, green: 0.420, blue: 1.0)
    private let orange = Color(red: 0.960, green: 0.420, blue: 0.0)

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * s, y: y * s)
            }

            // Background
            let background = Path(
                roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                cornerRadius: cornerStyle ? s * 0.2237 : 0
            )
            context.fill(background, with: .color(blue))

            // "Z" as a route
            var route = Path()
            route.move(to: point(0.30, 0.33))
            route.addLine(to: point(0.70, 0.33))
            route.addLine(to: point(0.30, 0.67))
            route.addLine(to: point(0.70, 0.67))
            context.stroke(
                route,
                with: .color(.white),
                style: StrokeStyle(lineWidth: s * 0.09, lineCap: .round, lineJoin: .round)
            )

            // Origin node (white ring with blue center)
            circle(context, center: point(0.30, 0.33), radius: s * 0.075, color: .white)
            circle(context, center: point(0.30, 0.33), radius: s * 0.035, color: blue)

            // Destination node (orange dot)
            circle(context, center: point(0.70, 0.67), radius: s * 0.062, color: orange)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("SZSIM")
    }

    private func circle(_ context: GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }
}

#Preview {
    HStack(spacing: 16) {
        LogoMark(size: 36)
        LogoMark(size: 64)
        LogoMark(size: 128)
    }
    .padding()
}
