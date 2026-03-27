import SwiftUI

struct WorkdayInsightsCardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今日节奏")
                        .font(.system(size: 24, weight: .black, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(model.workPhaseSubtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                phaseBadge
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                insightTile(title: "今日封顶", value: model.todayCapText, tint: AppTheme.textPrimary)
                insightTile(title: "还可回血", value: model.remainingPotentialText, tint: AppTheme.green)
                insightTile(title: "节奏进度", value: "\(Int(model.scheduleProgress * 100))%", tint: AppTheme.gold)
                insightTile(title: "剩余工时", value: model.remainingWorkText, tint: AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 12) {
                progressLine(title: "日程进度", progress: model.scheduleProgress, tint: AppTheme.gold)
                progressLine(title: "实际回血", progress: model.earningsProgressToCap, tint: AppTheme.green)
            }
        }
        .padding(24)
        .background(AppCardBackground())
    }

    private var phaseBadge: some View {
        Text(model.workPhaseTitle)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(model.workState == .active ? .white : AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(model.workState == .active ? AppTheme.green : AppTheme.beige)
            )
    }

    private func insightTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardStrong.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }

    private func progressLine(title: String, progress: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(AppTheme.beige.opacity(0.8))
                        .frame(height: 10)

                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: max(10, proxy.size.width * min(1, max(0, progress))), height: 10)
                        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: progress)
                }
            }
            .frame(height: 10)
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }
}
