import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(red: 0.91, green: 0.96, blue: 0.98)
    static let backgroundBottom = Color(red: 0.98, green: 0.93, blue: 0.89)
    static let card = Color.white.opacity(0.84)
    static let cardStrong = Color.white.opacity(0.96)
    static let stroke = Color(red: 0.75, green: 0.84, blue: 0.89)
    static let divider = Color(red: 0.83, green: 0.88, blue: 0.91)
    static let textPrimary = Color(red: 0.11, green: 0.18, blue: 0.27)
    static let textSecondary = Color(red: 0.30, green: 0.40, blue: 0.50)
    static let textMuted = Color(red: 0.44, green: 0.53, blue: 0.61)
    static let green = Color(red: 0.12, green: 0.58, blue: 0.63)
    static let greenSoft = Color(red: 0.86, green: 0.96, blue: 0.95)
    static let beige = Color(red: 0.99, green: 0.88, blue: 0.78)
    static let beigeStrong = Color(red: 0.94, green: 0.64, blue: 0.42)
    static let gold = Color(red: 0.95, green: 0.48, blue: 0.33)
    static let shadow = Color.black.opacity(0.08)
}

struct AppPanelBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.cardStrong.opacity(0.45))
                .frame(width: 280, height: 280)
                .blur(radius: 10)
                .offset(x: -180, y: -220)

            Circle()
                .fill(AppTheme.greenSoft.opacity(0.55))
                .frame(width: 240, height: 240)
                .blur(radius: 12)
                .offset(x: 220, y: -160)
        }
        .ignoresSafeArea()
    }
}

struct AppCardBackground: View {
    var highlighted: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(highlighted ? AppTheme.cardStrong : AppTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(highlighted ? AppTheme.beigeStrong : AppTheme.stroke.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 20, y: 10)
    }
}
