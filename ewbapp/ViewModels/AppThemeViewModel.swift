import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case system   = "system"
    case light    = "light"
    case dark     = "dark"
    case redLight = "redLight"

    var displayName: String {
        switch self {
        case .system:   return "System"
        case .light:    return "Light"
        case .dark:     return "Dark"
        case .redLight: return "Red-Light"
        }
    }
}

class AppThemeViewModel: ObservableObject {
    @AppStorage("appTheme") var theme: AppTheme = .system

    var colorScheme: ColorScheme? {
        switch theme {
        case .system:   return nil
        case .light:    return .light
        case .dark:     return .dark
        case .redLight: return .dark
        }
    }

    var isRedLightMode: Bool { theme == .redLight }
}
