import SwiftUI
import UIKit

enum AppColors {
    static func pinkCard(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#FBE3EB") : Color(hex: "#E88AB8")
    }
    static func pinkPrimary(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#E88AB8") : Color(hex:"#FADBE6")
    }
    static func lavenderQuick(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#E6D9FF") : Color(hex: "#E6D9FF")
    }
    static func background(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#FFF9F5") : Color(hex: "#2A2A28")
    }
    static func white(for theme: AppTheme) -> Color {
        theme == .light ? Color.white : Color.black
    }
    static func black(for theme: AppTheme) -> Color {
        theme == .light ? Color.black : Color.white
    }
}

enum AppFonts {
    // VT323
    static func vt323(_ size: CGFloat) -> Font {
        .custom("VT323-Regular", size: size)
    }

    // SF Compact Rounded
    static func rounded(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}

enum AppLayout {
    static let cornerRadius: CGFloat = 12
    static let screenPadding: CGFloat = 20
}

extension Color {
    /// Initialize a Color from a hex string like "#RRGGBB" or "#RRGGBBAA" (alpha optional).
    /// If parsing fails, defaults to clear.
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        // Accept 6 (RGB) or 8 (RGBA) characters
        var rgba: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgba) else {
            self = .clear
            return
        }

        let r, g, b, a: Double
        switch hexString.count {
        case 6:
            r = Double((rgba & 0xFF0000) >> 16) / 255.0
            g = Double((rgba & 0x00FF00) >> 8) / 255.0
            b = Double(rgba & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgba & 0xFF000000) >> 24) / 255.0
            g = Double((rgba & 0x00FF0000) >> 16) / 255.0
            b = Double((rgba & 0x0000FF00) >> 8) / 255.0
            a = Double(rgba & 0x000000FF) / 255.0
        default:
            self = .clear
            return
        }

        self = Color(red: r, green: g, blue: b, opacity: a)
    }
}

struct TabBarStyler {

    static func apply(theme: AppTheme) {
        let lavender = UIColor(AppColors.pinkPrimary(for: theme))
        let unselected = UIColor.gray

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = UIColor(
            AppColors.background(for: theme)
        )

        // Selected
        appearance.stackedLayoutAppearance.selected.iconColor = lavender
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: lavender
        ]

        // Unselected
        appearance.stackedLayoutAppearance.normal.iconColor = unselected
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselected
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
