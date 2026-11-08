import SwiftUI

struct MuscleRadarChart: View {
    let scores: [MuscleScore]

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 - 40

            ZStack {
                Canvas { context, _ in
                    guard !scores.isEmpty else { return }
                    for level in 1...4 {
                        let path = polygon(center: center, radius: radius * CGFloat(level) / 4)
                        context.stroke(path, with: .color(Theme.textTertiary.opacity(0.25)), lineWidth: 1)
                    }
                    for index in scores.indices {
                        var axis = Path()
                        axis.move(to: center)
                        axis.addLine(to: point(center: center, radius: radius, index: index))
                        context.stroke(axis, with: .color(Theme.textTertiary.opacity(0.2)), lineWidth: 1)
                    }
                    var dataPath = Path()
                    for (index, score) in scores.enumerated() {
                        let target = point(center: center, radius: radius * CGFloat(max(1, score.score)) / 10, index: index)
                        if index == 0 {
                            dataPath.move(to: target)
                        } else {
                            dataPath.addLine(to: target)
                        }
                    }
                    if let first = scores.first {
                        dataPath.addLine(to: point(center: center, radius: radius * CGFloat(max(1, first.score)) / 10, index: 0))
                    }
                    context.fill(dataPath, with: .color(Theme.orange.opacity(0.25)))
                    context.stroke(dataPath, with: .color(Theme.orange), lineWidth: 2)
                }

                ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
                    Text(score.muscle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .position(labelPoint(center: center, radius: radius + 22, index: index))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Muscle balance radar: " + scores.map { "\($0.muscle) \($0.score) of 10" }.joined(separator: ", "))
    }

    private func point(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
        guard !scores.isEmpty else { return center }
        let angle = -CGFloat.pi / 2 + 2 * CGFloat.pi * CGFloat(index) / CGFloat(scores.count)
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func labelPoint(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
        point(center: center, radius: radius, index: index)
    }

    private func polygon(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        guard !scores.isEmpty else { return path }
        for index in scores.indices {
            let target = point(center: center, radius: radius, index: index)
            if index == 0 {
                path.move(to: target)
            } else {
                path.addLine(to: target)
            }
        }
        path.closeSubpath()
        return path
    }
}
