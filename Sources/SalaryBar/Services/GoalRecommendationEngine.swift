import CryptoKit
import Foundation

enum GoalRecommendationEngine {
    static func recommendedGoals(for settings: AppSettings, projectedDailyEarnings: Double) -> [GoalItem] {
        let targetDaily = max(projectedDailyEarnings, settings.salary.mode == .hourly ? settings.salary.amount * 3 : projectedDailyEarnings)
        let maxAmount = max(36, targetDaily * 1.25)
        let minAmount = max(6, min(targetDaily * 0.08, 45))

        let sorted = catalog
            .filter { $0.amount >= minAmount && $0.amount <= maxAmount }
            .sorted { $0.amount < $1.amount }

        let selected = pickApproximatelyTen(from: sorted.isEmpty ? catalog : sorted)
        return selected.map { item in
            GoalItem(
                id: stableUUID(for: "\(item.title)-\(item.amount)"),
                title: item.title,
                amount: item.amount,
                icon: item.icon
            )
        }
    }

    private static func pickApproximatelyTen(from items: [GoalTemplate]) -> [GoalTemplate] {
        let unique = Array(items.prefix(18))
        guard unique.count > 10 else {
            return unique
        }

        let strideValue = Double(unique.count - 1) / 9.0
        var result: [GoalTemplate] = []
        var usedIndexes: Set<Int> = []

        for step in 0..<10 {
            let index = Int((Double(step) * strideValue).rounded())
            if !usedIndexes.contains(index), unique.indices.contains(index) {
                result.append(unique[index])
                usedIndexes.insert(index)
            }
        }

        if result.count < 10 {
            for index in unique.indices where !usedIndexes.contains(index) {
                result.append(unique[index])
                if result.count == 10 {
                    break
                }
            }
        }

        return result.sorted { $0.amount < $1.amount }
    }

    private static let catalog: [GoalTemplate] = [
        GoalTemplate("便利店热拿铁", 7, "cup.and.saucer"),
        GoalTemplate("早餐手抓饼", 9, "takeoutbag.and.cup.and.straw"),
        GoalTemplate("燕麦酸奶杯", 12, "carrot"),
        GoalTemplate("工作日轻食沙拉", 18, "leaf.circle"),
        GoalTemplate("鲜榨果汁", 22, "drop.circle"),
        GoalTemplate("地铁单日通勤", 28, "tram"),
        GoalTemplate("精品冰美式", 32, "mug"),
        GoalTemplate("办公室小蛋糕", 36, "birthday.cake"),
        GoalTemplate("晚饭加个硬菜", 42, "fork.knife.circle"),
        GoalTemplate("电影夜基金", 58, "film"),
        GoalTemplate("书店新书一本", 66, "book.closed"),
        GoalTemplate("周末 brunch", 88, "fork.knife"),
        GoalTemplate("鲜花小束", 99, "camera.macro"),
        GoalTemplate("耳机壳基金", 128, "headphones.circle"),
        GoalTemplate("健身单次课", 158, "figure.strengthtraining.traditional"),
        GoalTemplate("按摩放松", 188, "figure.cooldown"),
        GoalTemplate("桌面外设基金", 228, "keyboard"),
        GoalTemplate("跑鞋基金", 268, "figure.run.circle"),
        GoalTemplate("周末短途高铁", 328, "train.side.front.car"),
        GoalTemplate("演出门票基金", 398, "music.mic.circle"),
        GoalTemplate("微型旅行箱基金", 488, "suitcase.rolling"),
        GoalTemplate("机械键盘升级", 568, "laptopcomputer"),
        GoalTemplate("城市酒店一晚", 688, "building.2.crop.circle"),
        GoalTemplate("平板基金", 888, "ipad"),
        GoalTemplate("相机镜头基金", 1_288, "camera.aperture"),
    ]

    private static func stableUUID(for key: String) -> UUID {
        let digest = Insecure.MD5.hash(data: Data(key.utf8))
        let bytes = Array(digest)
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

private struct GoalTemplate {
    let title: String
    let amount: Double
    let icon: String

    init(_ title: String, _ amount: Double, _ icon: String) {
        self.title = title
        self.amount = amount
        self.icon = icon
    }
}
