import SwiftUI

struct AnimatedMenuBarIconView: View {
    let style: MenuBarIconStyle
    var size: CGFloat = 18
    var active: Bool = true
    var animated: Bool = true

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation(minimumInterval: 0.22, paused: !active)) { context in
                    iconBody(
                        frame: Int(context.date.timeIntervalSinceReferenceDate * 5)
                            .quotientAndRemainder(dividingBy: 4)
                            .remainder
                    )
                }
            } else {
                iconBody(frame: active ? 0 : 2)
            }
        }
    }

    @ViewBuilder
    private func iconBody(frame: Int) -> some View {
        ZStack {
            Circle()
                .fill(backgroundGradient)
                .frame(width: size, height: size)

            if style == .runningPerson {
                Image(systemName: frame.isMultiple(of: 2) ? "figure.run" : "figure.run.circle.fill")
                    .font(.system(size: size * 0.62, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(x: frame.isMultiple(of: 2) ? -0.6 : 0.8, y: frame.isMultiple(of: 2) ? 0 : -0.2)
            } else {
                Text(frame.isMultiple(of: 2) ? "🐈" : "🐾")
                    .font(.system(size: size * 0.72))
                    .offset(x: frame.isMultiple(of: 2) ? -0.4 : 0.8, y: frame == 1 ? -0.4 : 0.4)
            }
        }
        .overlay(alignment: .trailing) {
            if active {
                Capsule(style: .continuous)
                    .fill(AppTheme.gold.opacity(0.85))
                    .frame(width: size * 0.22, height: size * 0.56)
                    .blur(radius: 1)
                    .offset(x: size * 0.18)
                    .opacity(frame % 3 == 0 ? 0.7 : 0.2)
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: style == .runningPerson ? [AppTheme.green, AppTheme.gold] : [AppTheme.beigeStrong, AppTheme.gold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
