import CoreText
import SwiftUI
import UIKit

/// Typography of the Flat Glass theme: Inter 400/500/600 for text, Bebas Neue for display titles and big numbers.
/// Both are bundled in this package (SIL OFL 1.1, `Resources/Fonts`) and registered by `BWFont.registerFonts()`.
/// Every style scales with Dynamic Type; values keep tabular digits so columns of times line up.
public enum BWFont {
    /// PostScript names of the bundled faces.
    public enum Face {
        public static let regular = "Inter-Regular"
        public static let medium = "Inter-Medium"
        public static let semibold = "Inter-SemiBold"     // the heaviest weight: the theme never goes to 700
        public static let numeric = "BebasNeue-Regular"
    }

    private static let files = ["Inter_400Regular", "Inter_500Medium", "Inter_600SemiBold", "BebasNeue_400Regular"]
    @MainActor private static var registered = false

    /// Registers the bundled fonts with the process. Call once at launch, before the first view; repeated calls do
    /// nothing. Without it every style falls back to the system font, so a missing file never breaks a screen.
    @MainActor
    public static func registerFonts() {
        guard !registered else { return }
        registered = true
        for name in files {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// The theme's type scale (tokens.ts `type`) by text style, in points at the default text size.
    static func size(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 28
        case .title: return 24
        case .title2: return 20
        case .title3: return 18
        case .headline: return 16
        case .body: return 15
        case .callout: return 14
        case .subheadline: return 14
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 15
        }
    }

    /// Inter at a text style and weight. 700 and above map to SemiBold, under 400 to Regular.
    public static func inter(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        Font.custom(face(weight), size: size(style), relativeTo: style)
    }
    /// Inter at a fixed size, for printed pages (the scorecard) that must not follow Dynamic Type.
    public static func inter(fixed size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(face(weight), fixedSize: size)
    }
    /// Bebas Neue at a fixed size, for printed pages.
    public static func numeric(fixed size: CGFloat) -> Font {
        Font.custom(Face.numeric, fixedSize: size).monospacedDigit()
    }

    private static func face(_ weight: Font.Weight) -> String {
        switch weight {
        case .medium: return Face.medium
        case .semibold, .bold, .heavy, .black: return Face.semibold
        default: return Face.regular
        }
    }

    /// Bebas Neue sits smaller than Inter at the same point size (tall caps, narrow); this keeps titles and
    /// figures at the visual size the layout was made for.
    static let bebasScale: CGFloat = 1.25

    /// Display: Bebas Neue, uppercase titles ("TARGET 13 · STATION 2", session ids).
    public static func display(_ style: Font.TextStyle = .title2) -> Font {
        Font.custom(Face.numeric, size: size(style) * bebasScale, relativeTo: style)
    }
    /// Fixed-size display for hero numbers that should not grow without bound (scorecard, KPI).
    public static func display(size: CGFloat) -> Font {
        Font.custom(Face.numeric, fixedSize: size * bebasScale)
    }
    /// Heading in the body face (`type.h1`, 600).
    public static let heading = inter(.title, weight: .semibold)
    /// Card and sheet headings (`type.subtitle`).
    public static let subheading = inter(.title3, weight: .semibold)
    /// Body (`type.body`, 15).
    public static let body = inter(.body)
    /// Secondary text (14).
    public static let secondary = inter(.subheadline)
    /// Notes and footers (`type.caption`, 12-13).
    public static let note = inter(.footnote)
    /// Field and KPI labels: 11 / 600 / uppercase / tracked (`type.micro`). Apply with `.bwLabel()`.
    public static let label = inter(.caption2, weight: .semibold)
    /// Values that must line up: times, scores, ids. Inter with tabular digits.
    public static func value(_ style: Font.TextStyle = .body, weight: Font.Weight = .semibold) -> Font {
        inter(style, weight: weight).monospacedDigit()
    }
    /// Big figure (`type.figure`): Bebas Neue with tabular digits. Scores, KPI values.
    public static let valueLarge = Font.custom(Face.numeric, size: size(.title) * bebasScale + 4, relativeTo: .title).monospacedDigit()
    /// The timer readout (0.000): Bebas Neue at a fixed size so the digits never jump.
    public static func readout(size: CGFloat = 64) -> Font {
        Font.custom(Face.numeric, fixedSize: size * bebasScale).monospacedDigit()
    }
}

/// Letter spacing in points (tokens.ts `type` tracking).
public enum BWTracking {
    public static let display: CGFloat = 1.0       // Bebas titles
    public static let brand: CGFloat = 2.0
    public static let label: CGFloat = 0.8         // `type.micro` 0.88
    public static let section: CGFloat = 0.7       // `type.overline` 0.72
    public static let heading: CGFloat = -0.5      // `type.h1` -0.56
}

public extension View {
    /// Uppercase, tracked, secondary small label (`.form-label`, `.kpi-label`, `.vm-field-label`).
    func bwLabel(color: Color = BW.textSecondary) -> some View {
        font(BWFont.label).textCase(.uppercase).tracking(BWTracking.label).foregroundStyle(color)
    }
    /// Display text style (`.page-title`, `.card-title`).
    func bwDisplay(_ style: Font.TextStyle = .title2) -> some View {
        font(BWFont.display(style)).textCase(.uppercase).tracking(BWTracking.display).foregroundStyle(BW.ink)
    }
}

/// UIKit chrome that SwiftUI fonts don't reach: navigation bar titles in Inter SemiBold, scaled with Dynamic Type.
public enum BWAppearance {
    /// Registers the fonts and styles the navigation bars. Call once at launch.
    @MainActor
    public static func install() {
        BWFont.registerFonts()
        guard let large = UIFont(name: BWFont.Face.semibold, size: 30),
              let inline = UIFont(name: BWFont.Face.semibold, size: 17) else { return }
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
        bar.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)]
    }
}
