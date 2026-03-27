import SwiftUI

@main
struct SalaryBarApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            DashboardView(model: model)
                .frame(width: 460, height: 640)
        } label: {
            MenuBarLabelView(model: model)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("设置", id: "settings") {
            SettingsRootView(model: model)
                .frame(minWidth: 760, minHeight: 600)
        }
        .defaultSize(width: 860, height: 680)
    }
}
