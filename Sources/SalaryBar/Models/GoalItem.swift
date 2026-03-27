import Foundation

struct GoalItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var icon: String

    init(id: UUID = UUID(), title: String, amount: Double, icon: String = "sparkles") {
        self.id = id
        self.title = title
        self.amount = amount
        self.icon = icon
    }

    static let defaultGoals: [GoalItem] = [
        GoalItem(title: "一杯蜜雪冰城", amount: 5, icon: "cup.and.saucer"),
        GoalItem(title: "一碗热干面", amount: 15, icon: "takeoutbag.and.cup.and.straw"),
        GoalItem(title: "一杯喜茶", amount: 25, icon: "takeoutbag.and.cup.and.straw.fill"),
        GoalItem(title: "一份麦当劳套餐", amount: 35, icon: "fork.knife.circle"),
        GoalItem(title: "一张电影票", amount: 50, icon: "popcorn"),
        GoalItem(title: "一箱油油的零食", amount: 88, icon: "birthday.cake"),
        GoalItem(title: "一顿火锅", amount: 128, icon: "flame.circle"),
    ]
}
