import AppKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            AppPanelBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    if model.isConfigured {
                        if let unlockedGoal = model.latestUnlockedGoal {
                            CelebrationBannerView(goal: unlockedGoal) {
                                model.dismissCelebration()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        IncomeCardView(model: model)
                        WorkdayInsightsCardView(model: model)
                        GoalsCardView(model: model)
                    } else {
                        unconfiguredCard
                    }

                    actionBar
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                AnimatedMenuBarIconView(
                    style: model.settings.display.iconStyle,
                    size: 22,
                    active: model.workState == .active
                )
                Text("工资可视化")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppTheme.green)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.cardStrong)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppTheme.stroke.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.shadow, radius: 14, y: 6)
            )

            Text("打工回血条")
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Text(model.menuBarStatusText)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.top, 8)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: model.latestUnlockedGoal?.id)
    }

    private var unconfiguredCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("先完成工资配置")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("设置月薪或时薪、工作时间和午休时间后，顶部栏会开始按秒显示今天已经赚了多少钱。")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            Button("打开设置") {
                model.openSettingsWindow(openWindow)
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(AppCardBackground())
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button(model.isPaused ? "继续回血" : "暂停累计") {
                model.togglePause()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!model.isConfigured)

            Button("设置") {
                model.openSettingsWindow(openWindow)
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button("重置今日") {
                model.resetToday()
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(!model.isConfigured)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.card.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.stroke.opacity(0.42), lineWidth: 1)
                )
        )
    }
}

private struct CelebrationBannerView: View {
    let goal: GoalItem
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.gold.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: goal.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.gold)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("新目标已解锁")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.gold)
                Text(goal.title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), AppTheme.beige.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.beigeStrong.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: AppTheme.gold.opacity(0.14), radius: 12, y: 6)
    }
}

struct CardBackground: View {
    var body: some View {
        AppCardBackground()
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.green)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.green.opacity(0.7), lineWidth: 1)
                    )
            )
            .shadow(color: AppTheme.green.opacity(0.18), radius: 10, y: 4)
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.green)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.stroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.84 : 1)
    }
}
