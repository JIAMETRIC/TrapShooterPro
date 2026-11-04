import SwiftUI
import UIKit

/// The palette: Flat Glass · Brand Blue (Theme-Colors/AppTheme.swift, from the Android app's tokens.ts). Five brand
/// colours: blue #2596BE, grey #666666, light grey #EBEAEA, black and white; green, amber and red only for real status.
/// Every token is dynamic: light appearance first, dark appearance second. Contrast is checked against WCAG AA
/// (4.5:1 for text): where the theme's #2596BE would carry text it is replaced by the theme's deep blue #1A6F8E.
public enum BW {
    // MARK: brand
    public static let black = Color(hex: 0x000000)
    public static let white = Color(hex: 0xFFFFFF)
    /// Brand blue (`brand.primary`). Fills, bars, rules, selection. Not for text on light backgrounds (2.8:1).
    public static let brandBlue = Color(hex: 0x2596BE)
    /// Deep brand blue (`brand.link`). Carries white text at 5.7:1 and reads as text on light backgrounds at 4.7:1.
    public static let brandBlueDeep = Color(hex: 0x1A6F8E)
    /// Brand grey (`brand.secondary`).
    public static let brandGrey = Color(hex: 0x666666)
    /// Brand light grey (`brand.tertiary`).
    public static let brandLight = Color(hex: 0xEBEAEA)

    // MARK: semantic, light / dark
    /// The strongest text: scores, titles, values. Black, white in dark mode.
    public static let ink = Color.dynamic(light: 0x000000, dark: 0xFFFFFF)
    /// Card and sheet background: the theme's glass (white 55 % on #EBEAEA, white 8 % on black) as an opaque colour,
    /// so zebra rows and stacked cards keep one shade.
    public static let paper = Color.dynamic(light: 0xF6F6F6, dark: 0x141414)
    /// Page background (`theme.bg`): flat, no gradients.
    public static let surface = Color.dynamic(light: 0xEBEAEA, dark: 0x000000)
    /// Zebra rows and quiet boxes.
    public static let surfaceAlt = Color.dynamic(light: 0xEFEFEF, dark: 0x1F1F1F)
    /// Hairlines and dividers (`theme.divider`).
    public static let border = Color.dynamic(light: 0xE2E1E1, dark: 0x2E2E2E)
    /// Control borders (`theme.outline`, grey at 35 %).
    public static let borderStrong = Color.dynamic(light: 0xC4C4C4, dark: 0x333333)
    /// Glass buttons and icon buttons (`glassStrong`, white 60 % / 8 %).
    public static let glassFill = Color.dynamic(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.6, darkOpacity: 0.08)
    /// The glass edge round cards and buttons (`glassBorder`, white 85 % / 16 %).
    public static let glassBorder = Color.dynamic(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.85, darkOpacity: 0.16)
    /// Body text.
    public static let text = Color.dynamic(light: 0x000000, dark: 0xFFFFFF)
    /// Secondary text and field labels. 7.0:1 on `surface`.
    public static let textSecondary = Color.dynamic(light: 0x4D4D4D, dark: 0xD9D9D9)
    /// Muted text, units, hints (`theme.textMuted`, brand grey). 4.8:1 on `surface`, 5.3:1 on `paper`.
    public static let textMuted = Color.dynamic(light: 0x666666, dark: 0xA6A6A6)
    /// Text on an ink fill.
    public static let onInk = Color.dynamic(light: 0xFFFFFF, dark: 0x000000)
    /// Translucent fills on ink panels (`rgba(255,255,255,0.10)` on black).
    public static func inkOverlay(_ opacity: Double) -> Color { onInk.opacity(opacity) }

    // MARK: accent
    /// Brand blue for non-text marks: bars, rules, the current target, chart fills.
    public static let accent = brandBlue
    /// Filled controls that carry white text: primary buttons, selected choices, table headers (5.7:1).
    public static let accentFill = brandBlueDeep
    /// Text and icons on `accentFill`.
    public static let onAccent = white
    /// Selected rows and soft highlights (`primaryTint`, blue 14 % / 24 %).
    public static let accentSoft = Color.dynamic(light: 0x2596BE, dark: 0x2596BE, lightOpacity: 0.14, darkOpacity: 0.24)
    /// System tint (toggles, Form buttons, links): deep blue on light screens (5.7:1 on white), brand blue on dark
    /// (5.0:1 on the dark grouped rows).
    public static let tint = Color.dynamic(light: 0x1A6F8E, dark: 0x2596BE)
    /// The bottom nav's glass (`navSurface`, white 65 % / black 88 %).
    public static let navFill = Color.dynamic(light: 0xFFFFFF, dark: 0x000000, lightOpacity: 0.65, darkOpacity: 0.88)

    // MARK: panel
    /// The timer readout and the round-complete panel: black in both appearances, for sunlight on the range.
    public static let panel = black
    /// Text on `panel`.
    public static let onPanel = white
    /// Edge of a `panel` so it stays a shape on the black dark-mode page.
    public static let panelBorder = Color.dynamic(light: 0x000000, dark: 0xFFFFFF, lightOpacity: 0, darkOpacity: 0.16)
    /// Translucent fills and rings on a `panel`.
    public static func panelOverlay(_ opacity: Double) -> Color { onPanel.opacity(opacity) }

    // MARK: status (the only colour in the system)
    public struct Status: Sendable {
        public let foreground: Color
        public let background: Color
        public let border: Color
        public let dot: Color
    }
    /// #065F46 on #ECFDF5, border #A7F3D0, dot #10B981.
    public static let success = Status(
        foreground: .dynamic(light: 0x065F46, dark: 0xA7F3D0),
        background: .dynamic(light: 0xECFDF5, dark: 0x10B981, darkOpacity: 0.15),
        border: .dynamic(light: 0xA7F3D0, dark: 0x10B981, darkOpacity: 0.35),
        dot: Color(hex: 0x10B981))
    /// #92400E on #FFFBEB, border #FDE68A, dot #F59E0B.
    public static let warning = Status(
        foreground: .dynamic(light: 0x92400E, dark: 0xFDE68A),
        background: .dynamic(light: 0xFFFBEB, dark: 0xF59E0B, darkOpacity: 0.15),
        border: .dynamic(light: 0xFDE68A, dark: 0xF59E0B, darkOpacity: 0.35),
        dot: Color(hex: 0xF59E0B))
    /// #991B1B on #FEF2F2, border #FECACA, dot #EF4444.
    public static let danger = Status(
        foreground: .dynamic(light: 0x991B1B, dark: 0xFECACA),
        background: .dynamic(light: 0xFEF2F2, dark: 0xEF4444, darkOpacity: 0.15),
        border: .dynamic(light: 0xFECACA, dark: 0xEF4444, darkOpacity: 0.35),
        dot: Color(hex: 0xEF4444))
    /// Grey pill (`.status-badge`, `.vm-badge-info`).
    public static let neutral = Status(foreground: textSecondary, background: surface, border: border, dot: textMuted)
    /// Selected choice: deep blue fill, white text.
    public static let accentStatus = Status(foreground: onAccent, background: accentFill, border: accentFill, dot: onAccent)

    // MARK: shooting domain
    /// Hit with the first shot (G).
    public static let hitFirst = success
    /// Hit with the second shot (Y).
    public static let hitSecond = warning
    /// Lost (R).
    public static let lost = danger
    /// Destructive button (`.btn-danger-red` #DC3545).
    /// Dark fill is red-600, not red-500: white text on it needs 4.5:1 (≈4.8:1 here; red-500 gave ≈3.8:1).
    public static let destructive = Color.dynamic(light: 0xDC3545, dark: 0xDC2626)
    /// Text on `destructive`, white in both appearances.
    public static let onDestructive = Color(hex: 0xFFFFFF)
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// A colour that follows the appearance: `light` hex in light mode, `dark` hex in dark mode.
    static func dynamic(light: UInt32, dark: UInt32, lightOpacity: Double = 1, darkOpacity: Double = 1) -> Color {
        Color(uiColor: UIColor { trait in
            let isDark = trait.userInterfaceStyle == .dark
            return UIColor(hex: isDark ? dark : light, alpha: isDark ? darkOpacity : lightOpacity)
        })
    }
}

public extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
