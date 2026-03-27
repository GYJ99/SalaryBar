import Foundation

struct TimeOfDay: Codable, Equatable {
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    var totalMinutes: Int {
        hour * 60 + minute
    }

    func applied(to date: Date, calendar: Calendar) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        ) ?? date
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortTitle: String {
        switch self {
        case .monday:
            return "一"
        case .tuesday:
            return "二"
        case .wednesday:
            return "三"
        case .thursday:
            return "四"
        case .friday:
            return "五"
        case .saturday:
            return "六"
        case .sunday:
            return "日"
        }
    }

    var title: String {
        switch self {
        case .monday:
            return "周一"
        case .tuesday:
            return "周二"
        case .wednesday:
            return "周三"
        case .thursday:
            return "周四"
        case .friday:
            return "周五"
        case .saturday:
            return "周六"
        case .sunday:
            return "周日"
        }
    }
}
