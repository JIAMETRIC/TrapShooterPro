import SwiftUI

/// Spacing, radii, strokes, shadows, control sizes and motion, in points.
public enum BWMetrics {
    // Spacing scale (reference: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32, 48)
    public static let s1: CGFloat = 4
    public static let s2: CGFloat = 8
    public static let s3: CGFloat = 12
    public static let s4: CGFloat = 16
    public static let s5: CGFloat = 20
    public static let s6: CGFloat = 24
    public static let s8: CGFloat = 32
    public static let s12: CGFloat = 48
    /// Screen side gutter (`.page-content` 20/24; phones 16).
    public static let gutter: CGFloat = 16

    // Radii (tokens.ts `radius`: chip 10, control 12, card 16, dialog 18, pills capsule)
    public static let radiusXS: CGFloat = 4
    /// Icon chips, small ghost buttons.
    public static let radiusSM: CGFloat = 10
    /// Buttons, inputs, icon buttons.
    public static let radiusMD: CGFloat = 12
    /// Cards, panels, the iPad sidebar item.
    public static let radiusLG: CGFloat = 16
    /// Dialogs and form sheets.
    public static let radiusXL: CGFloat = 18

    // Strokes
    public static let hairline: CGFloat = 1
    public static let stroke: CGFloat = 1.5
    /// Section label underline, grand total rule.
    public static let rule: CGFloat = 2
    /// KPI card top accent.
    public static let accentTop: CGFloat = 3
    /// Identity banner left accent.
    public static let accentLeft: CGFloat = 4

    // Control sizes. The reference uses 48 (inputs, submit), 40 (actions), 28-38 (icon buttons);
    // iOS needs 44 pt minimum tap targets, so icon buttons are 44.
    public static let controlHeight: CGFloat = 48
    public static let actionHeight: CGFloat = 44
    public static let iconButton: CGFloat = 44
    public static let statusDot: CGFloat = 8
    public static let featureBullet: CGFloat = 6

    /// Shadows, all tinted blue rgb(20,71,108) (tokens.ts `shadow`). SwiftUI's radius is half the CSS blur.
    public struct Shadow: Sendable {
        public let opacity: Double, radius: CGFloat, y: CGFloat
        /// `shadow.primary` 0 4px 8px 15 %: buttons, chips, tiles.
        public static let control = Shadow(opacity: 0.15, radius: 4, y: 4)
        /// `shadow.secondary` 0 8px 16px 20 %: cards.
        public static let card = Shadow(opacity: 0.20, radius: 8, y: 8)
        /// Raised previews (the scorecard on the round detail).
        public static let raised = Shadow(opacity: 0.20, radius: 8, y: 8)
        public static let sheet = Shadow(opacity: 0.20, radius: 30, y: 20)
        /// No shadow (a disabled primary button lies flat).
        public static let none = Shadow(opacity: 0, radius: 0, y: 0)
    }
    /// The shadow tint, #14476C.
    public static let shadowTint = Color(hex: 0x14476C)
}

/// Motion: reference transitions, as SwiftUI animations.
public enum BWMotion {
    /// Pressed states: the theme's 180 ms cubic-bezier(0.22, 1, 0.36, 1).
    public static let fast = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.18)
    /// `0.2s` colour and opacity changes.
    public static let standard = Animation.easeInOut(duration: 0.2)
    /// `--t-sidebar: 0.28s cubic-bezier(0.4, 0, 0.2, 1)` layout changes.
    public static let layout = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.28)
    /// `vmBoxIn: 0.24s cubic-bezier(0.34, 1.10, 0.64, 1)` sheets and cards appearing (slight overshoot).
    public static let appear = Animation.spring(response: 0.3, dampingFraction: 0.8)
    /// Pressed scale of buttons (`transform: scale(0.99)`).
    public static let pressedScale: CGFloat = 0.98
    /// Pressed opacity of filled buttons (`opacity: 0.9`).
    public static let pressedOpacity: Double = 0.9
}

public extension View {
    func bwShadow(_ s: BWMetrics.Shadow) -> some View {
        shadow(color: BWMetrics.shadowTint.opacity(s.opacity), radius: s.radius, x: 0, y: s.y)
    }
}
