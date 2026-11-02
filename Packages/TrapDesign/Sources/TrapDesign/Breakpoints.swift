import SwiftUI

/// Width classes for phone, 8" iPad and 11"/13" iPad, in points of the window (not the screen: Split View and
/// Slide Over change the window). Pure, so layouts are testable.
public enum Breakpoint: Int, Comparable, Sendable {
    case phone, tabletSmall, tabletLarge
    public static func < (a: Breakpoint, b: Breakpoint) -> Bool { a.rawValue < b.rawValue }

    public init(width: CGFloat) { self = width >= 1100 ? .tabletLarge : width >= 600 ? .tabletSmall : .phone }

    /// Master‑detail instead of a single column.
    public var isSplit: Bool { self != .phone }
    /// Width share of the master column: 40 % on an 8" iPad, 35 % on a large one.
    public var masterFraction: CGFloat { self == .tabletLarge ? 0.35 : 0.40 }
    /// Persistent sidebar width in landscape‑wide layouts; 0 means use the tab bar.
    public var sidebarWidth: CGFloat { switch self { case .phone: return 0; case .tabletSmall: return 180; case .tabletLarge: return 220 } }
    /// 44 pt on phones (HIG), 48 pt on tablets (stylus and gloves).
    public var minTouchTarget: CGFloat { self == .phone ? 44 : 48 }
    /// Columns for KPI tiles.
    public var tileColumns: Int { switch self { case .phone: return 2; case .tabletSmall: return 3; case .tabletLarge: return 4 } }
}

private struct BreakpointKey: EnvironmentKey { static let defaultValue = Breakpoint.phone }
public extension EnvironmentValues {
    var breakpoint: Breakpoint {
        get { self[BreakpointKey.self] }
        set { self[BreakpointKey.self] = newValue }
    }
}

/// Measures the window and publishes `\.breakpoint` to everything below. Apply once at the root.
public struct BreakpointReader<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        GeometryReader { geo in
            content
                .environment(\.breakpoint, Breakpoint(width: geo.size.width))
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct SplitActiveKey: EnvironmentKey { static let defaultValue = false }
public extension EnvironmentValues {
    /// True below an `AdaptiveSplit` that shows master and detail side by side; false when it shows the master
    /// alone and the detail has to be pushed with navigation.
    var splitActive: Bool {
        get { self[SplitActiveKey.self] }
        set { self[SplitActiveKey.self] = newValue }
    }
}

/// Master‑detail on tablets, master only on phones (the caller pushes the detail with navigation there).
///
/// The breakpoint describes the window, but the split lives in whatever space it is given: beside an iPad sidebar
/// that is the window minus the sidebar. It splits only when the master column would be at least as wide as the
/// narrowest phone layout; otherwise it shows the master alone, as on a phone. Children read `\.splitActive`.
public struct AdaptiveSplit<Master: View, Detail: View>: View {
    /// The narrowest supported phone width (iPhone SE, iPhone mini): every master screen is laid out for it.
    public static var minMasterWidth: CGFloat { 375 }

    /// Whether a split of `width` points shows master and detail side by side.
    public static func splits(width: CGFloat, breakpoint: Breakpoint) -> Bool {
        breakpoint.isSplit && width * breakpoint.masterFraction >= minMasterWidth
    }

    @Environment(\.breakpoint) private var breakpoint
    let master: Master
    let detail: Detail
    public init(@ViewBuilder master: () -> Master, @ViewBuilder detail: () -> Detail) {
        self.master = master(); self.detail = detail()
    }
    @ViewBuilder public var body: some View {
        if !breakpoint.isSplit {
            master                                                  // phone: same view tree as before, no reader
        } else {
            GeometryReader { geo in
                if Self.splits(width: geo.size.width, breakpoint: breakpoint) {
                    HStack(spacing: 0) {
                        master.frame(width: (geo.size.width * breakpoint.masterFraction).rounded())
                        Rectangle().fill(BW.border).frame(width: BWMetrics.hairline)
                        detail.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .environment(\.splitActive, true)
                } else {
                    master.environment(\.splitActive, false)
                }
            }
        }
    }
}

/// Hardware keyboard on iPad (and the Record screen with a Bluetooth keyboard at the range).
/// Attach with `.keyboardShortcut(BWKeys.start)` on the matching buttons.
public enum BWKeys {
    public static let start = KeyboardShortcut(.space, modifiers: [])
    public static let left = KeyboardShortcut("1", modifiers: [])
    public static let straight = KeyboardShortcut("2", modifiers: [])
    public static let right = KeyboardShortcut("3", modifiers: [])
    public static let hitFirst = KeyboardShortcut("g", modifiers: [])
    public static let hitSecond = KeyboardShortcut("y", modifiers: [])
    public static let lost = KeyboardShortcut("r", modifiers: [])
    public static let noTarget = KeyboardShortcut("n", modifiers: [])
    public static let undo = KeyboardShortcut("z", modifiers: .command)
    public static let previous = KeyboardShortcut(.leftArrow, modifiers: [])
    public static let next = KeyboardShortcut(.rightArrow, modifiers: [])
    public static let save = KeyboardShortcut("s", modifiers: .command)
    public static let share = KeyboardShortcut("e", modifiers: .command)
}

public extension View {
    /// The minimum tap target for the current breakpoint.
    func bwTouchTarget(_ breakpoint: Breakpoint) -> some View {
        frame(minWidth: breakpoint.minTouchTarget, minHeight: breakpoint.minTouchTarget)
    }
}
