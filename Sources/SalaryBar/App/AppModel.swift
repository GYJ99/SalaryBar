import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            store.save(settings: settings)
            syncPlatformPreferences(oldValue: oldValue, newValue: settings)
        }
    }

    @Published var runtime: RuntimeState {
        didSet {
            store.save(runtime: runtime)
        }
    }

    @Published private(set) var now: Date = Date()
    @Published private(set) var latestUnlockedGoal: GoalItem?

    private let store: AppStorageStore
    private let notificationManager: NotificationManager
    private let launchAtLoginService: LaunchAtLoginService
    private let calendar: Calendar
    private var timer: Timer?

    init(
        store: AppStorageStore = .shared,
        notificationManager: NotificationManager = .shared,
        launchAtLoginService: LaunchAtLoginService = .shared,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.notificationManager = notificationManager
        self.launchAtLoginService = launchAtLoginService
        self.calendar = calendar

        let loadedSettings = store.loadSettings()
        let loadedRuntime = store.loadRuntime()
        settings = loadedSettings
        runtime = loadedRuntime

        normalizeRuntimeIfNeeded(referenceDate: now)
        syncLaunchAtLoginPreference(enabled: loadedSettings.system.launchAtLogin)
        if loadedSettings.system.notificationsEnabled {
            Task {
                await notificationManager.requestAuthorizationIfNeeded()
            }
        }

        refresh()
        startTimer()
    }

    var isConfigured: Bool {
        settings.salary.amount > 0
    }

    var isPaused: Bool {
        runtime.manualPaused
    }

    var workState: WorkState {
        guard isConfigured else {
            return .unconfigured
        }
        if runtime.manualPaused {
            return .paused
        }
        return EarningsCalculator.isWorkMoment(
            date: now,
            schedule: settings.schedule,
            calendar: calendar
        ) ? .active : .offHours
    }

    var earningsSnapshot: EarningsSnapshot {
        let perSecond = EarningsCalculator.perSecondRate(from: settings)
        let scheduledSeconds = EarningsCalculator.scheduledSeconds(
            from: calendar.startOfDay(for: now),
            to: now,
            schedule: settings.schedule,
            calendar: calendar
        )
        let pausedSeconds = pausedWorkSecondsUntilNow
        let effectiveSeconds = max(0, scheduledSeconds - pausedSeconds)
        let todayEarned = perSecond * effectiveSeconds
        let hourly = perSecond * 3600
        let minute = perSecond * 60
        return EarningsSnapshot(
            todayEarned: todayEarned,
            perSecond: perSecond,
            perMinute: minute,
            perHour: hourly,
            workedSecondsToday: effectiveSeconds
        )
    }

    var currentGoal: GoalItem? {
        goalItems
            .sorted { $0.amount < $1.amount }
            .first(where: { $0.amount > earningsSnapshot.todayEarned + 0.000_1 })
    }

    var unlockedGoals: [GoalItem] {
        goalItems.filter { $0.amount <= earningsSnapshot.todayEarned + 0.000_1 }
    }

    var unlockedGoalCount: Int {
        unlockedGoals.count
    }

    var goalItems: [GoalItem] {
        GoalRecommendationEngine.recommendedGoals(
            for: settings,
            projectedDailyEarnings: projectedDailyEarnings
        )
    }

    var goalProgress: Double {
        guard let goal = currentGoal else {
            return goalItems.isEmpty ? 0 : 1
        }
        guard goal.amount > 0 else {
            return 0
        }
        return min(1, max(0, earningsSnapshot.todayEarned / goal.amount))
    }

    var nextGoalRemainingAmount: Double {
        guard let currentGoal else {
            return 0
        }
        return max(0, currentGoal.amount - earningsSnapshot.todayEarned)
    }

    var menuBarDisplayText: String {
        switch workState {
        case .unconfigured:
            return "去设置"
        case .paused:
            return "暂停 " + CurrencyFormatter.string(
                earningsSnapshot.todayEarned,
                currencySymbol: settings.display.currencySymbol,
                fractionDigits: settings.display.decimalPlaces
            )
        case .offHours:
            if settings.display.menuBarStyle == .statusOnly {
                return "未开工"
            }
            return CurrencyFormatter.string(
                earningsSnapshot.todayEarned,
                currencySymbol: settings.display.currencySymbol,
                fractionDigits: settings.display.decimalPlaces
            )
        case .active:
            return CurrencyFormatter.string(
                earningsSnapshot.todayEarned,
                currencySymbol: settings.display.currencySymbol,
                fractionDigits: settings.display.decimalPlaces
            )
        }
    }

    var menuBarStatusText: String {
        switch workState {
        case .unconfigured:
            return "未配置"
        case .paused:
            return "暂停中"
        case .offHours:
            return "非工作时段"
        case .active:
            return "工作中"
        }
    }

    var timerText: String {
        DurationFormatter.string(from: earningsSnapshot.workedSecondsToday)
    }

    var totalScheduledWorkSecondsToday: TimeInterval {
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        return EarningsCalculator.scheduledSeconds(
            from: startOfDay,
            to: endOfDay,
            schedule: settings.schedule,
            calendar: calendar
        )
    }

    var scheduledSecondsElapsedToday: TimeInterval {
        EarningsCalculator.scheduledSeconds(
            from: calendar.startOfDay(for: now),
            to: now,
            schedule: settings.schedule,
            calendar: calendar
        )
    }

    var remainingScheduledWorkSecondsToday: TimeInterval {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return EarningsCalculator.scheduledSeconds(
            from: now,
            to: startOfTomorrow,
            schedule: settings.schedule,
            calendar: calendar
        )
    }

    var projectedDailyEarnings: Double {
        earningsSnapshot.perSecond * totalScheduledWorkSecondsToday
    }

    var remainingPotentialToday: Double {
        max(0, projectedDailyEarnings - earningsSnapshot.todayEarned)
    }

    var scheduleProgress: Double {
        guard totalScheduledWorkSecondsToday > 0 else {
            return 0
        }
        return min(1, max(0, scheduledSecondsElapsedToday / totalScheduledWorkSecondsToday))
    }

    var earningsProgressToCap: Double {
        guard totalScheduledWorkSecondsToday > 0 else {
            return 0
        }
        return min(1, max(0, earningsSnapshot.workedSecondsToday / totalScheduledWorkSecondsToday))
    }

    var workPhase: WorkPhase {
        switch workState {
        case .unconfigured:
            return .unconfigured
        case .paused:
            return .paused
        case .offHours:
            if remainingScheduledWorkSecondsToday > 0 {
                return .waiting
            }
            return .done
        case .active:
            switch scheduleProgress {
            case ..<0.18:
                return .warmup
            case ..<0.68:
                return .flow
            case ..<0.92:
                return .sprint
            default:
                return .closing
            }
        }
    }

    var workPhaseTitle: String {
        workPhase.title
    }

    var workPhaseSubtitle: String {
        switch workPhase {
        case .unconfigured:
            return "先把工资和作息配好，顶部栏才能开始回血。"
        case .paused:
            return "已经暂停累计，恢复后会继续沿着今天的节奏推进。"
        case .waiting:
            return "当前不在计薪时段，但今天后面还有可回血时间。"
        case .done:
            return "今天的计薪时段已经结束，明天会自动重新开始。"
        case .warmup:
            return "刚进入工作段，适合处理启动成本高的任务。"
        case .flow:
            return "现在是稳定输出区，最适合推进核心工作。"
        case .sprint:
            return "已经进入后半程，适合收口和冲刺目标。"
        case .closing:
            return "快到收工段了，做收尾和复盘最合适。"
        }
    }

    var remainingWorkText: String {
        if remainingScheduledWorkSecondsToday <= 0 {
            return "今日已收工"
        }
        return DurationFormatter.compactString(from: remainingScheduledWorkSecondsToday)
    }

    var todayCapText: String {
        CurrencyFormatter.string(
            projectedDailyEarnings,
            currencySymbol: settings.display.currencySymbol,
            fractionDigits: settings.display.decimalPlaces
        )
    }

    var remainingPotentialText: String {
        CurrencyFormatter.string(
            remainingPotentialToday,
            currencySymbol: settings.display.currencySymbol,
            fractionDigits: settings.display.decimalPlaces
        )
    }

    func refresh(referenceDate: Date = Date()) {
        now = referenceDate
        normalizeRuntimeIfNeeded(referenceDate: referenceDate)
        maybeNotifyUnlockedGoals()
    }

    func togglePause() {
        guard isConfigured else {
            return
        }

        let referenceDate = Date()
        normalizeRuntimeIfNeeded(referenceDate: referenceDate)

        if runtime.manualPaused {
            if let pauseStartedAt = runtime.pauseStartedAt {
                runtime.accumulatedPausedWorkSeconds += EarningsCalculator.scheduledSeconds(
                    from: pauseStartedAt,
                    to: referenceDate,
                    schedule: settings.schedule,
                    calendar: calendar
                )
            }
            runtime.manualPaused = false
            runtime.pauseStartedAt = nil
        } else {
            runtime.manualPaused = true
            runtime.pauseStartedAt = referenceDate
        }
        refresh(referenceDate: referenceDate)
    }

    func resetToday() {
        let currentDay = calendar.startOfDay(for: Date())
        runtime.dayAnchor = currentDay
        runtime.accumulatedPausedWorkSeconds = 0
        runtime.pauseStartedAt = runtime.manualPaused ? Date() : nil
        runtime.notifiedGoalIDs = []
        refresh()
    }

    func addGoal() {
        settings.goals.append(GoalItem(title: "自定义回血基金", amount: max(projectedDailyEarnings * 1.35, 128), icon: "sparkles"))
    }

    func applySchedulePreset(_ preset: SchedulePreset) {
        settings.schedule = preset.schedule
    }

    func removeGoal(id: UUID) {
        settings.goals.removeAll { $0.id == id }
    }

    func moveGoal(from source: IndexSet, to destination: Int) {
        settings.goals.move(fromOffsets: source, toOffset: destination)
    }

    func sortGoals() {
        settings.goals.sort { $0.amount < $1.amount }
    }

    func weekdayBinding(for weekday: Weekday) -> Binding<Bool> {
        Binding(
            get: { self.settings.schedule.workdays.contains(weekday) },
            set: { isOn in
                if isOn {
                    self.settings.schedule.workdays.insert(weekday)
                } else {
                    self.settings.schedule.workdays.remove(weekday)
                }
            }
        )
    }

    func openSettingsWindow(_ openWindow: OpenWindowAction) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }

    func dismissCelebration() {
        latestUnlockedGoal = nil
    }

    private var pausedWorkSecondsUntilNow: TimeInterval {
        let ongoingPauseSeconds: TimeInterval
        if runtime.manualPaused, let pauseStartedAt = runtime.pauseStartedAt {
            ongoingPauseSeconds = EarningsCalculator.scheduledSeconds(
                from: pauseStartedAt,
                to: now,
                schedule: settings.schedule,
                calendar: calendar
            )
        } else {
            ongoingPauseSeconds = 0
        }
        return runtime.accumulatedPausedWorkSeconds + ongoingPauseSeconds
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func normalizeRuntimeIfNeeded(referenceDate: Date) {
        let currentDay = calendar.startOfDay(for: referenceDate)
        guard currentDay != runtime.dayAnchor else {
            return
        }
        runtime.dayAnchor = currentDay
        runtime.accumulatedPausedWorkSeconds = 0
        runtime.notifiedGoalIDs = []
        if runtime.manualPaused {
            runtime.pauseStartedAt = currentDay
        } else {
            runtime.pauseStartedAt = nil
        }
    }

    private func maybeNotifyUnlockedGoals() {
        guard settings.system.notificationsEnabled else {
            return
        }

        let unlocked = unlockedGoals.filter { !runtime.notifiedGoalIDs.contains($0.id) }
        guard !unlocked.isEmpty else {
            return
        }

        for goal in unlocked {
            runtime.notifiedGoalIDs.append(goal.id)
            latestUnlockedGoal = goal
            Task {
                await notificationManager.requestAuthorizationIfNeeded()
                await notificationManager.sendGoalUnlockedNotification(goal: goal)
            }

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                if self.latestUnlockedGoal?.id == goal.id {
                    self.latestUnlockedGoal = nil
                }
            }
        }
    }

    private func syncPlatformPreferences(oldValue: AppSettings, newValue: AppSettings) {
        if oldValue.system.notificationsEnabled != newValue.system.notificationsEnabled,
           newValue.system.notificationsEnabled {
            Task {
                await notificationManager.requestAuthorizationIfNeeded()
            }
        }

        if oldValue.system.launchAtLogin != newValue.system.launchAtLogin {
            syncLaunchAtLoginPreference(enabled: newValue.system.launchAtLogin)
        }
    }

    private func syncLaunchAtLoginPreference(enabled: Bool) {
        do {
            try launchAtLoginService.setEnabled(enabled)
        } catch {
            print("Launch at login update failed: \(error)")
        }
    }
}

enum WorkPhase {
    case unconfigured
    case paused
    case waiting
    case done
    case warmup
    case flow
    case sprint
    case closing

    var title: String {
        switch self {
        case .unconfigured:
            return "未配置"
        case .paused:
            return "暂停中"
        case .waiting:
            return "等待开工"
        case .done:
            return "今日收工"
        case .warmup:
            return "热身区"
        case .flow:
            return "稳定输出"
        case .sprint:
            return "冲刺区"
        case .closing:
            return "收尾区"
        }
    }
}

enum WorkState {
    case unconfigured
    case active
    case paused
    case offHours
}

struct EarningsSnapshot {
    let todayEarned: Double
    let perSecond: Double
    let perMinute: Double
    let perHour: Double
    let workedSecondsToday: TimeInterval
}
