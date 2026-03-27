import Foundation

enum EarningsCalculator {
    static func perSecondRate(from settings: AppSettings) -> Double {
        switch settings.salary.mode {
        case .hourly:
            return max(0, settings.salary.amount) / 3600
        case .monthly:
            guard settings.salary.monthlyWorkHours > 0 else {
                return 0
            }
            return max(0, settings.salary.amount) / settings.salary.monthlyWorkHours / 3600
        }
    }

    static func isWorkMoment(date: Date, schedule: ScheduleSettings, calendar: Calendar) -> Bool {
        guard let weekday = Weekday(rawValue: calendar.component(.weekday, from: date)),
              schedule.workdays.contains(weekday) else {
            return false
        }

        let currentMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let withinMain = currentMinutes >= schedule.startTime.totalMinutes && currentMinutes < schedule.endTime.totalMinutes
        guard withinMain else {
            return false
        }

        if schedule.breakEnabled {
            let withinBreak = currentMinutes >= schedule.breakStart.totalMinutes && currentMinutes < schedule.breakEnd.totalMinutes
            return !withinBreak
        }

        return true
    }

    static func scheduledSeconds(
        from start: Date,
        to end: Date,
        schedule: ScheduleSettings,
        calendar: Calendar
    ) -> TimeInterval {
        guard end > start else {
            return 0
        }

        var total: TimeInterval = 0
        var cursor = start

        while cursor < end {
            let dayStart = calendar.startOfDay(for: cursor)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                break
            }

            let segmentEnd = min(end, nextDay)

            if let weekday = Weekday(rawValue: calendar.component(.weekday, from: dayStart)),
               schedule.workdays.contains(weekday) {
                let workStart = schedule.startTime.applied(to: dayStart, calendar: calendar)
                let workEnd = schedule.endTime.applied(to: dayStart, calendar: calendar)
                total += overlapSeconds(rangeStart: start, rangeEnd: segmentEnd, intervalStart: workStart, intervalEnd: workEnd)

                if schedule.breakEnabled {
                    let breakStart = schedule.breakStart.applied(to: dayStart, calendar: calendar)
                    let breakEnd = schedule.breakEnd.applied(to: dayStart, calendar: calendar)
                    total -= overlapSeconds(rangeStart: start, rangeEnd: segmentEnd, intervalStart: breakStart, intervalEnd: breakEnd)
                }
            }

            cursor = nextDay
        }

        return max(0, total)
    }

    private static func overlapSeconds(
        rangeStart: Date,
        rangeEnd: Date,
        intervalStart: Date,
        intervalEnd: Date
    ) -> TimeInterval {
        let overlapStart = max(rangeStart, intervalStart)
        let overlapEnd = min(rangeEnd, intervalEnd)
        guard overlapEnd > overlapStart else {
            return 0
        }
        return overlapEnd.timeIntervalSince(overlapStart)
    }
}
