import SwiftUI

struct IncomeCardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Label(model.timerText, systemImage: "clock")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.gold)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.beige.opacity(0.55))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(AppTheme.stroke, lineWidth: 1)
                            )
                    )
                Spacer()

                Text(model.menuBarStatusText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(model.isPaused ? AppTheme.textSecondary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(model.isPaused ? AppTheme.beige : AppTheme.green)
                    )
            }

            VStack(spacing: 6) {
                Text(CurrencyFormatter.string(
                    model.earningsSnapshot.todayEarned,
                    currencySymbol: model.settings.display.currencySymbol,
                    fractionDigits: model.settings.display.decimalPlaces
                ))
                .font(.system(size: 54, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: model.earningsSnapshot.todayEarned)

                Text("今日已赚")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
            }

            Divider()
                .overlay(AppTheme.divider)

            HStack(alignment: .top, spacing: 12) {
                MetricView(title: "每秒", value: model.earningsSnapshot.perSecond, symbol: model.settings.display.currencySymbol, digits: 4)
                MetricView(title: "每分钟", value: model.earningsSnapshot.perMinute, symbol: model.settings.display.currencySymbol, digits: 2)
                MetricView(title: "每小时", value: model.earningsSnapshot.perHour, symbol: model.settings.display.currencySymbol, digits: 2)
            }

            VStack(alignment: .leading, spacing: 12) {
                if let goal = model.currentGoal {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("下一目标")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textMuted)
                            Text(goal.title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(CurrencyFormatter.string(goal.amount, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 0))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.green)
                            Text("还差 \(CurrencyFormatter.string(model.nextGoalRemainingAmount, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 2))")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(AppTheme.beige.opacity(0.85))
                                .frame(height: 10)

                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.green, Color(red: 0.39, green: 0.60, blue: 0.42)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(12, proxy.size.width * model.goalProgress), height: 10)
                                .animation(.spring(response: 0.4, dampingFraction: 0.86), value: model.goalProgress)
                        }
                    }
                    .frame(height: 10)
                } else {
                    Label("今日目标已全部解锁", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.green)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.beige.opacity(0.34))
            )

            Button(model.isPaused ? "继续回血" : "收工休息") {
                model.togglePause()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(24)
        .background(AppCardBackground(highlighted: true))
    }
}

private struct MetricView: View {
    let title: String
    let value: Double
    let symbol: String
    let digits: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.green)

            Text(CurrencyFormatter.string(value, currencySymbol: symbol, fractionDigits: digits))
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.28), value: value)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.beige.opacity(0.24))
        )
    }
}
