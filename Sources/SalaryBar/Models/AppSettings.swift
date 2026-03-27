import Foundation

struct AppSettings: Codable {
    var salary: SalarySettings
    var schedule: ScheduleSettings
    var display: DisplaySettings
    var system: SystemSettings
    var goals: [GoalItem]

    static let `default` = AppSettings(
        salary: .default,
        schedule: .default,
        display: .default,
        system: .default,
        goals: GoalItem.defaultGoals
    )
}

struct SalarySettings: Codable {
    var mode: SalaryMode
    var amount: Double
    var monthlyWorkHours: Double

    static let `default` = SalarySettings(
        mode: .monthly,
        amount: 15_000,
        monthlyWorkHours: 174
    )
}

enum SalaryMode: String, Codable, CaseIterable, Identifiable {
    case monthly
    case hourly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            return "月薪"
        case .hourly:
            return "时薪"
        }
    }
}

struct ScheduleSettings: Codable {
    var workdays: Set<Weekday>
    var startTime: TimeOfDay
    var endTime: TimeOfDay
    var breakEnabled: Bool
    var breakStart: TimeOfDay
    var breakEnd: TimeOfDay

    static let `default` = ScheduleSettings(
        workdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 0),
        breakEnabled: true,
        breakStart: TimeOfDay(hour: 12, minute: 30),
        breakEnd: TimeOfDay(hour: 13, minute: 30)
    )
}

struct SchedulePreset: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let schedule: ScheduleSettings

    static let all: [SchedulePreset] = [
        SchedulePreset(
            id: "955",
            title: "标准 955",
            subtitle: "09:00 - 18:00，午休 1h",
            schedule: ScheduleSettings(
                workdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                startTime: TimeOfDay(hour: 9, minute: 0),
                endTime: TimeOfDay(hour: 18, minute: 0),
                breakEnabled: true,
                breakStart: TimeOfDay(hour: 12, minute: 30),
                breakEnd: TimeOfDay(hour: 13, minute: 30)
            )
        ),
        SchedulePreset(
            id: "965",
            title: "通勤 965",
            subtitle: "09:30 - 18:30，午休 1h",
            schedule: ScheduleSettings(
                workdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                startTime: TimeOfDay(hour: 9, minute: 30),
                endTime: TimeOfDay(hour: 18, minute: 30),
                breakEnabled: true,
                breakStart: TimeOfDay(hour: 12, minute: 30),
                breakEnd: TimeOfDay(hour: 13, minute: 30)
            )
        ),
        SchedulePreset(
            id: "1075",
            title: "晚一点 1075",
            subtitle: "10:00 - 19:00，午休 1h",
            schedule: ScheduleSettings(
                workdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                startTime: TimeOfDay(hour: 10, minute: 0),
                endTime: TimeOfDay(hour: 19, minute: 0),
                breakEnabled: true,
                breakStart: TimeOfDay(hour: 13, minute: 0),
                breakEnd: TimeOfDay(hour: 14, minute: 0)
            )
        ),
    ]
}

struct DisplaySettings: Codable {
    var menuBarStyle: MenuBarDisplayStyle
    var decimalPlaces: Int
    var currencySymbol: String
    var showMenuBarIcon: Bool
    var iconStyle: MenuBarIconStyle

    static let `default` = DisplaySettings(
        menuBarStyle: .amountOnly,
        decimalPlaces: 2,
        currencySymbol: "￥",
        showMenuBarIcon: true,
        iconStyle: .runningCat
    )

    init(
        menuBarStyle: MenuBarDisplayStyle,
        decimalPlaces: Int,
        currencySymbol: String,
        showMenuBarIcon: Bool,
        iconStyle: MenuBarIconStyle
    ) {
        self.menuBarStyle = menuBarStyle
        self.decimalPlaces = decimalPlaces
        self.currencySymbol = currencySymbol
        self.showMenuBarIcon = showMenuBarIcon
        self.iconStyle = iconStyle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        menuBarStyle = try container.decodeIfPresent(MenuBarDisplayStyle.self, forKey: .menuBarStyle) ?? .amountOnly
        decimalPlaces = try container.decodeIfPresent(Int.self, forKey: .decimalPlaces) ?? 2
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol) ?? "￥"
        showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? true
        iconStyle = try container.decodeIfPresent(MenuBarIconStyle.self, forKey: .iconStyle) ?? .runningCat
    }
}

enum MenuBarIconStyle: String, Codable, CaseIterable, Identifiable {
    case runningPerson
    case runningCat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .runningPerson:
            return "跑步小人"
        case .runningCat:
            return "跑动小猫"
        }
    }
}

enum MenuBarDisplayStyle: String, Codable, CaseIterable, Identifiable {
    case amountOnly
    case iconAndAmount
    case statusOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .amountOnly:
            return "仅金额"
        case .iconAndAmount:
            return "图标 + 金额"
        case .statusOnly:
            return "状态文案"
        }
    }
}

struct SystemSettings: Codable {
    var notificationsEnabled: Bool
    var launchAtLogin: Bool

    static let `default` = SystemSettings(
        notificationsEnabled: true,
        launchAtLogin: false
    )
}
