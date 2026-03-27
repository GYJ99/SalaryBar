import XCTest
@testable import SalaryBar

final class EarningsCalculatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testHourlyRateConvertsToPerSecond() {
        var settings = AppSettings.default
        settings.salary.mode = .hourly
        settings.salary.amount = 72

        let perSecond = EarningsCalculator.perSecondRate(from: settings)

        XCTAssertEqual(perSecond, 0.02, accuracy: 0.000_001)
    }

    func testMonthlyRateUsesMonthlyHours() {
        var settings = AppSettings.default
        settings.salary.mode = .monthly
        settings.salary.amount = 17_400
        settings.salary.monthlyWorkHours = 174

        let perHour = EarningsCalculator.perSecondRate(from: settings) * 3600

        XCTAssertEqual(perHour, 100, accuracy: 0.000_001)
    }

    func testScheduledSecondsExcludeBreak() {
        let baseDay = date(2026, 3, 27, 9, 0)
        let noon = date(2026, 3, 27, 14, 0)

        let seconds = EarningsCalculator.scheduledSeconds(
            from: baseDay,
            to: noon,
            schedule: .default,
            calendar: calendar
        )

        XCTAssertEqual(seconds, 4 * 3600, accuracy: 0.5)
    }

    func testNonWorkdayReturnsZero() {
        let sundayStart = date(2026, 3, 29, 9, 0)
        let sundayEnd = date(2026, 3, 29, 18, 0)

        let seconds = EarningsCalculator.scheduledSeconds(
            from: sundayStart,
            to: sundayEnd,
            schedule: .default,
            calendar: calendar
        )

        XCTAssertEqual(seconds, 0, accuracy: 0.5)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
