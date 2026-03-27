import SwiftUI

struct GoalsCardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("搞钱成就")
                        .font(.system(size: 26, weight: .black, design: .serif))
                        .foregroundStyle(Color.white)
                    Text("\(model.unlockedGoalCount) / \(model.goalItems.count) 已解锁")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.84))
                }
                Spacer()
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.green, AppTheme.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(
                        .rect(
                            topLeadingRadius: 28,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 28
                        )
                    )
            )

            VStack(spacing: 12) {
                ForEach(model.goalItems.sorted(by: { $0.amount < $1.amount })) { goal in
                    GoalRow(
                        goal: goal,
                        isUnlocked: goal.amount <= model.earningsSnapshot.todayEarned + 0.000_1,
                        isCurrent: model.currentGoal?.id == goal.id,
                        currencySymbol: model.settings.display.currencySymbol
                    )
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.cardStrong)
            )
        }
        .background(
            AppCardBackground()
        )
    }
}

private struct GoalRow: View {
    let goal: GoalItem
    let isUnlocked: Bool
    let isCurrent: Bool
    let currencySymbol: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: goal.icon)
                    .foregroundStyle(iconForeground)
                    .font(.system(size: 17, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(CurrencyFormatter.string(goal.amount, currencySymbol: currencySymbol, fractionDigits: 0))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.green)
            } else if isCurrent {
                Text("进行中")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.beige)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isCurrent ? AppTheme.beige.opacity(0.38) : Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, style: StrokeStyle(lineWidth: 1, dash: isCurrent ? [] : [5, 5]))
        )
        .scaleEffect(isCurrent ? 1.015 : 1)
        .shadow(color: isCurrent ? AppTheme.gold.opacity(0.15) : .clear, radius: 10, y: 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isCurrent)
    }

    private var iconBackground: Color {
        if isUnlocked {
            return AppTheme.greenSoft
        }
        if isCurrent {
            return AppTheme.beige
        }
        return Color(red: 0.95, green: 0.95, blue: 0.95)
    }

    private var iconForeground: Color {
        if isUnlocked {
            return AppTheme.green
        }
        if isCurrent {
            return AppTheme.gold
        }
        return Color(red: 0.65, green: 0.62, blue: 0.58)
    }

    private var borderColor: Color {
        if isCurrent {
            return AppTheme.beigeStrong
        }
        return AppTheme.divider
    }
}
