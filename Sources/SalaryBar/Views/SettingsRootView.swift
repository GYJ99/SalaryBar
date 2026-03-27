import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case salary
    case schedule
    case goals
    case display

    var id: String { rawValue }

    var title: String {
        switch self {
        case .salary:
            return "工资"
        case .schedule:
            return "时间"
        case .goals:
            return "目标"
        case .display:
            return "显示"
        }
    }

    var subtitle: String {
        switch self {
        case .salary:
            return "计薪方式与换算"
        case .schedule:
            return "工作日与午休"
        case .goals:
            return "回血清单"
        case .display:
            return "顶部栏与系统偏好"
        }
    }

    var icon: String {
        switch self {
        case .salary:
            return "banknote"
        case .schedule:
            return "clock"
        case .goals:
            return "target"
        case .display:
            return "menubar.rectangle"
        }
    }
}

struct SettingsRootView: View {
    @ObservedObject var model: AppModel
    @State private var selectedSection: SettingsSection = .salary

    var body: some View {
        ZStack {
            AppPanelBackground()

            HStack(spacing: 18) {
                sidebar
                detailPanel
            }
            .padding(20)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SalaryBar")
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("调整你的收入、时间和回血节奏。")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(SettingsSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: section.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(section.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                Text(section.subtitle)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            Spacer()
                        }
                        .foregroundStyle(selectedSection == section ? Color.white : AppTheme.textPrimary)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedSection == section ? AppTheme.green : AppTheme.cardStrong.opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selectedSection == section ? AppTheme.green : AppTheme.stroke.opacity(0.65), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("当前效率")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)

                VStack(alignment: .leading, spacing: 8) {
                    infoChip(title: "每小时", value: CurrencyFormatter.string(model.earningsSnapshot.perHour, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 2))
                    infoChip(title: "今日已赚", value: CurrencyFormatter.string(model.earningsSnapshot.todayEarned, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 2))
                }
            }
            .padding(16)
            .background(AppCardBackground())
        }
        .frame(width: 250, alignment: .topLeading)
    }

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedSection.title)
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(selectedSection.subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            ScrollView {
                VStack(spacing: 16) {
                    switch selectedSection {
                    case .salary:
                        salarySection
                    case .schedule:
                        scheduleSection
                    case .goals:
                        goalsSection
                    case .display:
                        displaySection
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(22)
        .background(AppCardBackground(highlighted: true))
    }

    private var salarySection: some View {
        VStack(spacing: 16) {
            settingsCard(title: "计薪规则", description: "先定义工资来源，再决定系统按秒如何换算。") {
                VStack(spacing: 14) {
                    settingsRow(title: "薪资模式") {
                        Picker("", selection: salaryModeBinding) {
                            ForEach(SalaryMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }

                    settingsRow(title: "工资数") {
                        TextField("0", value: salaryAmountBinding, format: .number.precision(.fractionLength(0...2)))
                            .frame(width: 180)
                            .textFieldStyle(.roundedBorder)
                    }

                    if model.settings.salary.mode == .monthly {
                        settingsRow(title: "月工时") {
                            TextField("174", value: monthlyHoursBinding, format: .number.precision(.fractionLength(0...1)))
                                .frame(width: 180)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }

            settingsCard(title: "实时预览", description: "工资更新是按真实时间差结算，下面是当前折算结果。") {
                HStack(spacing: 12) {
                    previewMetric(title: "每秒", value: CurrencyFormatter.string(model.earningsSnapshot.perSecond, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 4))
                    previewMetric(title: "每分钟", value: CurrencyFormatter.string(model.earningsSnapshot.perMinute, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 2))
                    previewMetric(title: "每小时", value: CurrencyFormatter.string(model.earningsSnapshot.perHour, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 2))
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(spacing: 16) {
            settingsCard(title: "工作日", description: "只有被选中的工作日才会进入自动累计。") {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        ForEach(Weekday.allCases.filter { $0 != .sunday && $0 != .saturday } + [.saturday, .sunday]) { weekday in
                            Toggle(weekday.shortTitle, isOn: model.weekdayBinding(for: weekday))
                                .toggleStyle(.button)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(SchedulePreset.all) { preset in
                                Button {
                                    model.applySchedulePreset(preset)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(preset.title)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                        Text(preset.subtitle)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                    }
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(AppTheme.cardStrong.opacity(0.88))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(AppTheme.stroke.opacity(0.8), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            settingsCard(title: "上下班时间", description: "工资只会在工作时间内增长，超出时段自动停止。") {
                VStack(spacing: 14) {
                    timeSettingsRow(title: "上班时间", binding: startTimeBinding)
                    timeSettingsRow(title: "下班时间", binding: endTimeBinding)
                }
            }

            settingsCard(title: "午休", description: "午休时段默认不累计，可以直接关闭。") {
                VStack(spacing: 14) {
                    settingsRow(title: "启用午休") {
                        Toggle("", isOn: breakEnabledBinding)
                            .labelsHidden()
                    }

                    if model.settings.schedule.breakEnabled {
                        timeSettingsRow(title: "午休开始", binding: breakStartBinding)
                        timeSettingsRow(title: "午休结束", binding: breakEndBinding)
                    }
                }
            }
        }
    }

    private var goalsSection: some View {
        VStack(spacing: 16) {
            settingsCard(title: "智能回血目标", description: "系统会根据你的工资和今日可赚上限，自动生成约 10 个更贴近现实消费层级的目标。") {
                VStack(spacing: 14) {
                    HStack {
                        Text("\(model.unlockedGoalCount) / \(model.goalItems.count) 已解锁")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.green)
                        Spacer()
                        Text("随工资动态匹配")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule(style: .continuous).fill(AppTheme.gold))
                    }

                    VStack(spacing: 12) {
                        ForEach(model.goalItems) { goal in
                            HStack(spacing: 12) {
                                Image(systemName: goal.icon)
                                    .frame(width: 28)
                                    .foregroundStyle(model.currentGoal?.id == goal.id ? AppTheme.gold : AppTheme.green)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(model.currentGoal?.id == goal.id ? "当前冲刺目标" : "系统推荐")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textMuted)
                                }

                                Spacer()

                                Text(CurrencyFormatter.string(goal.amount, currencySymbol: model.settings.display.currencySymbol, fractionDigits: 0))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(model.currentGoal?.id == goal.id ? AppTheme.gold : AppTheme.textPrimary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(model.currentGoal?.id == goal.id ? AppTheme.beige.opacity(0.36) : AppTheme.cardStrong.opacity(0.9))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(model.currentGoal?.id == goal.id ? AppTheme.beigeStrong : AppTheme.divider, lineWidth: 1)
                            )
                        }
                    }

                    Text("工资变动后，这一组目标会自动切换到更匹配的消费层级。日薪较高时会出现更大的基金型目标，日薪较低时则以高频小满足为主。")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }

    private var displaySection: some View {
        VStack(spacing: 16) {
            settingsCard(title: "顶部栏", description: "尽量控制信息密度，避免菜单栏过长或抖动。") {
                VStack(spacing: 14) {
                    settingsRow(title: "显示样式") {
                        Picker("", selection: menuBarStyleBinding) {
                            ForEach(MenuBarDisplayStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                        .frame(width: 180)
                    }

                    settingsRow(title: "显示图标") {
                        Toggle("", isOn: showIconBinding)
                            .labelsHidden()
                    }

                    settingsRow(title: "图标风格") {
                        Picker("", selection: iconStyleBinding) {
                            ForEach(MenuBarIconStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                        .frame(width: 180)
                    }

                    settingsRow(title: "图标预览") {
                        HStack(spacing: 12) {
                            AnimatedMenuBarIconView(
                                style: model.settings.display.iconStyle,
                                size: 26,
                                active: true
                            )
                            Text(model.settings.display.iconStyle.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.cardStrong)
                        )
                    }

                    settingsRow(title: "小数位") {
                        Stepper(value: decimalPlacesBinding, in: 0...4) {
                            Text("\(model.settings.display.decimalPlaces)")
                                .frame(width: 30)
                        }
                        .frame(width: 140)
                    }

                    settingsRow(title: "货币符号") {
                        TextField("￥", text: currencySymbolBinding)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            settingsCard(title: "系统", description: "这些能力会影响后台常驻行为和系统权限。") {
                VStack(spacing: 14) {
                    settingsRow(title: "目标解锁通知") {
                        Toggle("", isOn: notificationsEnabledBinding)
                            .labelsHidden()
                    }

                    settingsRow(title: "开机启动") {
                        Toggle("", isOn: launchAtLoginBinding)
                            .labelsHidden()
                    }
                }
            }
        }
    }

    private func infoChip(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func settingsCard<Content: View>(title: String, description: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppCardBackground())
    }

    private func settingsRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 96, alignment: .leading)

            Spacer()

            content()
        }
    }

    private func timeSettingsRow(title: String, binding: Binding<Date>) -> some View {
        settingsRow(title: title) {
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }

    private func previewMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.green)
            Text(value)
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.beige.opacity(0.35))
        )
    }

    private var salaryModeBinding: Binding<SalaryMode> {
        Binding(
            get: { model.settings.salary.mode },
            set: { model.settings.salary.mode = $0 }
        )
    }

    private var salaryAmountBinding: Binding<Double> {
        Binding(
            get: { model.settings.salary.amount },
            set: { model.settings.salary.amount = max(0, $0) }
        )
    }

    private var monthlyHoursBinding: Binding<Double> {
        Binding(
            get: { model.settings.salary.monthlyWorkHours },
            set: { model.settings.salary.monthlyWorkHours = max(1, $0) }
        )
    }

    private var breakEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.settings.schedule.breakEnabled },
            set: { model.settings.schedule.breakEnabled = $0 }
        )
    }

    private var menuBarStyleBinding: Binding<MenuBarDisplayStyle> {
        Binding(
            get: { model.settings.display.menuBarStyle },
            set: { model.settings.display.menuBarStyle = $0 }
        )
    }

    private var showIconBinding: Binding<Bool> {
        Binding(
            get: { model.settings.display.showMenuBarIcon },
            set: { model.settings.display.showMenuBarIcon = $0 }
        )
    }

    private var iconStyleBinding: Binding<MenuBarIconStyle> {
        Binding(
            get: { model.settings.display.iconStyle },
            set: { model.settings.display.iconStyle = $0 }
        )
    }

    private var decimalPlacesBinding: Binding<Int> {
        Binding(
            get: { model.settings.display.decimalPlaces },
            set: { model.settings.display.decimalPlaces = $0 }
        )
    }

    private var currencySymbolBinding: Binding<String> {
        Binding(
            get: { model.settings.display.currencySymbol },
            set: { model.settings.display.currencySymbol = String($0.prefix(2)) }
        )
    }

    private var notificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.settings.system.notificationsEnabled },
            set: { model.settings.system.notificationsEnabled = $0 }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.settings.system.launchAtLogin },
            set: { model.settings.system.launchAtLogin = $0 }
        )
    }

    private var startTimeBinding: Binding<Date> {
        binding(for: \.startTime)
    }

    private var endTimeBinding: Binding<Date> {
        binding(for: \.endTime)
    }

    private var breakStartBinding: Binding<Date> {
        binding(for: \.breakStart)
    }

    private var breakEndBinding: Binding<Date> {
        binding(for: \.breakEnd)
    }

    private func binding(for keyPath: WritableKeyPath<ScheduleSettings, TimeOfDay>) -> Binding<Date> {
        Binding(
            get: {
                model.settings.schedule[keyPath: keyPath].applied(to: Date(), calendar: .current)
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                model.settings.schedule[keyPath: keyPath] = TimeOfDay(
                    hour: components.hour ?? 0,
                    minute: components.minute ?? 0
                )
            }
        )
    }

}
