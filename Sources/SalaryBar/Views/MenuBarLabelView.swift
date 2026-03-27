import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            if model.settings.display.showMenuBarIcon {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text(labelText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var labelText: String {
        switch model.settings.display.menuBarStyle {
        case .amountOnly, .iconAndAmount:
            return model.menuBarDisplayText
        case .statusOnly:
            return model.menuBarStatusText
        }
    }

    private var iconName: String {
        switch model.settings.display.iconStyle {
        case .runningPerson:
            return model.workState == .active ? "figure.run" : "figure.walk"
        case .runningCat:
            return "pawprint.fill"
        }
    }
}
