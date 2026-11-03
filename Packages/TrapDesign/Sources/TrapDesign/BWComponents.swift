import SwiftUI

// MARK: Surfaces

/// Glass card (`GlassCard`): paper fill, 1 pt white glass edge, 16 pt radius, blue `card` shadow.
public struct BWCardModifier: ViewModifier {
    public var padding: CGFloat
    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: BWMetrics.radiusLG, style: .continuous)
        content
            .padding(padding)
            .background(BW.paper, in: shape)
            .overlay(shape.strokeBorder(BW.glassBorder, lineWidth: BWMetrics.hairline))
            .bwShadow(.card)
    }
}

/// `.kpi-card` / `.vm-kpi-card`: a card with a 3 pt brand-blue rule along the top.
public struct BWAccentTopModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            Rectangle().fill(BW.accent).frame(height: BWMetrics.accentTop)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: BWMetrics.radiusLG, topTrailingRadius: BWMetrics.radiusLG))
        }
    }
}

/// `.vm-identity-banner`: a card with a 4 pt brand-blue rule along the leading edge.
public struct BWAccentLeadingModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.overlay(alignment: .leading) {
            Rectangle().fill(BW.accent).frame(width: BWMetrics.accentLeft)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: BWMetrics.radiusLG, bottomLeadingRadius: BWMetrics.radiusLG))
        }
    }
}

public extension View {
    func bwCard(padding: CGFloat = BWMetrics.s4) -> some View { modifier(BWCardModifier(padding: padding)) }
    func bwAccentTop() -> some View { modifier(BWAccentTopModifier()) }
    func bwAccentLeading() -> some View { modifier(BWAccentLeadingModifier()) }
}

// MARK: Text pieces

/// Section title (`SectionTitle`, `type.overline`): uppercase, tracked, muted, no rule.
public struct BWSectionLabel<Trailing: View>: View {
    let title: String
    let trailing: Trailing
    public init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.trailing = trailing()
    }
    public var body: some View {
        HStack {
            Text(title).font(BWFont.inter(.caption, weight: .semibold)).textCase(.uppercase).tracking(BWTracking.section)
                .foregroundStyle(BW.textSecondary)
            Spacer(minLength: 0)
            trailing
        }
        .accessibilityAddTraits(.isHeader)
    }
}

public extension BWSectionLabel where Trailing == EmptyView {
    init(_ title: String) { self.init(title, trailing: { EmptyView() }) }
}

/// `.card-title`: Bebas Neue display title.
public struct BWCardTitle: View {
    let title: String
    public init(_ title: String) { self.title = title }
    public var body: some View {
        Text(title).bwDisplay(.title3)
            .accessibilityAddTraits(.isHeader)
    }
}

/// `.vm-field`: small uppercase label over a value.
public struct BWField: View {
    let label: String, value: String
    var mono = false, dim = false
    public init(_ label: String, value: String, mono: Bool = false, dim: Bool = false) {
        self.label = label; self.value = value; self.mono = mono; self.dim = dim
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: BWMetrics.s1) {
            Text(label).bwLabel()
            Text(value)
                .font(mono ? BWFont.value(.subheadline) : BWFont.secondary)
                .foregroundStyle(dim ? BW.textMuted : BW.text)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: KPI tile

/// KPI tile: label, large Bebas Neue figure with an optional unit, a sub line, brand-blue rule on top.
public struct BWKPITile: View {
    let label: String, value: String
    var unit: String? = nil, sub: String? = nil
    public init(_ label: String, value: String, unit: String? = nil, sub: String? = nil) {
        self.label = label; self.value = value; self.unit = unit; self.sub = sub
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: BWMetrics.s2) {
            Text(label).bwLabel(color: BW.textMuted)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(BWFont.valueLarge).foregroundStyle(BW.ink).tracking(0.5)
                    .lineLimit(1).minimumScaleFactor(0.5)                  // a number never breaks across lines
                if let unit {
                    Text(unit).font(BWFont.inter(.caption, weight: .semibold)).textCase(.uppercase).tracking(BWTracking.label).foregroundStyle(BW.textMuted)
                        .fixedSize()
                }
            }
            if let sub { Text(sub).font(BWFont.inter(.caption)).foregroundStyle(BW.textMuted) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCard(padding: BWMetrics.s4)
        .bwAccentTop()
        .accessibilityElement(children: .combine)
    }
}

// MARK: Pills and dots

/// `.status-dot`: 8 pt circle.
public struct BWStatusDot: View {
    let color: Color
    public init(_ color: Color) { self.color = color }
    public var body: some View { Circle().fill(color).frame(width: BWMetrics.statusDot, height: BWMetrics.statusDot) }
}

/// `.status-badge` / `.vm-badge` / `.hint-pill`: capsule with 1.5 pt border, small monospaced or uppercase text.
public struct BWPill: View {
    let text: String
    let status: BW.Status
    var dot = false, uppercase = false
    public init(_ text: String, status: BW.Status = BW.neutral, dot: Bool = false, uppercase: Bool = false) {
        self.text = text; self.status = status; self.dot = dot; self.uppercase = uppercase
    }
    public var body: some View {
        HStack(spacing: 6) {
            if dot { BWStatusDot(status.dot) }
            Text(text)
                .font(uppercase ? BWFont.inter(.caption2, weight: .semibold) : BWFont.value(.caption, weight: .semibold))
                .textCase(uppercase ? .uppercase : nil)
                .tracking(uppercase ? 0.5 : 0)
        }
        .foregroundStyle(status.foreground)
        .padding(.horizontal, BWMetrics.s3)
        .padding(.vertical, 5)
        .background(status.background, in: Capsule())
        .overlay(Capsule().strokeBorder(status.border, lineWidth: BWMetrics.stroke))
        .fixedSize()                                                       // full text at every size; never "H…"
    }
}

// MARK: Buttons

/// Primary button (`PrimaryButtonStyle`): deep brand-blue fill, white Inter SemiBold, 48 pt tall, 12 pt radius.
public struct BWPrimaryButtonStyle: ButtonStyle {
    public var height: CGFloat = BWMetrics.controlHeight
    @Environment(\.isEnabled) private var isEnabled
    public init(height: CGFloat = BWMetrics.controlHeight) { self.height = height }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BWFont.inter(.headline, weight: .semibold))
            .foregroundStyle(BW.onAccent)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(BW.accentFill, in: RoundedRectangle(cornerRadius: BWMetrics.radiusMD, style: .continuous))
            .bwShadow(isEnabled ? .control : .none)
            .opacity(configuration.isPressed ? BWMotion.pressedOpacity : 1)
            .bwPressEffect(configuration.isPressed)
    }
}

/// Glass button (`GlassButtonStyle`): white glass fill, white edge, blue `control` shadow, ink Inter Medium.
public struct BWSecondaryButtonStyle: ButtonStyle {
    public var height: CGFloat = BWMetrics.actionHeight
    public init(height: CGFloat = BWMetrics.actionHeight) { self.height = height }
    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: BWMetrics.radiusMD, style: .continuous)
        configuration.label
            .font(BWFont.inter(.body, weight: .medium))
            .foregroundStyle(BW.ink)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(configuration.isPressed ? BW.accentSoft : BW.glassFill, in: shape)
            .overlay(shape.strokeBorder(BW.glassBorder, lineWidth: BWMetrics.hairline))
            .bwShadow(.control)
            .bwPressEffect(configuration.isPressed)
    }
}

/// `.btn-danger-red`: for delete and NO TARGET-style destructive actions.
public struct BWDestructiveButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BWFont.inter(.headline, weight: .semibold))
            .foregroundStyle(BW.onDestructive)
            .frame(maxWidth: .infinity, minHeight: BWMetrics.actionHeight)
            .background(BW.destructive, in: RoundedRectangle(cornerRadius: BWMetrics.radiusMD, style: .continuous))
            .opacity(configuration.isPressed ? BWMotion.pressedOpacity : 1)
            .bwPressEffect(configuration.isPressed)
    }
}

/// Icon button (`AppIconButton`, glass): 44 pt square, glass fill and edge; on a panel, a faint white fill.
public struct BWIconButtonStyle: ButtonStyle {
    public var onInk = false
    public init(onInk: Bool = false) { self.onInk = onInk }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BWFont.inter(.body, weight: .semibold))
            .foregroundStyle(onInk ? BW.onPanel : BW.ink)
            .frame(width: BWMetrics.iconButton, height: BWMetrics.iconButton)
            .background(onInk ? BW.panelOverlay(configuration.isPressed ? 0.22 : 0.08) : (configuration.isPressed ? BW.accentSoft : BW.glassFill),
                        in: RoundedRectangle(cornerRadius: BWMetrics.radiusMD, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: BWMetrics.radiusMD, style: .continuous)
                .strokeBorder(onInk ? BW.panelOverlay(0.15) : BW.glassBorder, lineWidth: BWMetrics.hairline))
            .animation(BWMotion.fast, value: configuration.isPressed)
    }
}

/// The pressed shrink of the filled and outlined buttons. Under Reduce Motion the button does not move; the colour
/// and opacity change still fade.
public struct BWPressEffect: ViewModifier {
    let isPressed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && !reduceMotion ? BWMotion.pressedScale : 1)
            .animation(BWMotion.fast, value: isPressed)
    }
}
public extension View { func bwPressEffect(_ isPressed: Bool) -> some View { modifier(BWPressEffect(isPressed: isPressed)) } }

public extension ButtonStyle where Self == BWPrimaryButtonStyle { static var bwPrimary: BWPrimaryButtonStyle { BWPrimaryButtonStyle() } }
public extension ButtonStyle where Self == BWSecondaryButtonStyle { static var bwSecondary: BWSecondaryButtonStyle { BWSecondaryButtonStyle() } }
public extension ButtonStyle where Self == BWDestructiveButtonStyle { static var bwDestructive: BWDestructiveButtonStyle { BWDestructiveButtonStyle() } }
public extension ButtonStyle where Self == BWIconButtonStyle { static var bwIcon: BWIconButtonStyle { BWIconButtonStyle() } }

// MARK: Table

/// Table header: deep brand-blue row with uppercase white labels (5.7:1).
public struct BWTableHeader: View {
    let columns: [String]
    public init(_ columns: [String]) { self.columns = columns }
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, c in
                Text(c).font(BWFont.inter(.caption2, weight: .semibold)).textCase(.uppercase).tracking(0.8).bwTableCell()
            }
        }
        .foregroundStyle(BW.onAccent)
        .padding(.horizontal, BWMetrics.s3).padding(.vertical, 10)
        .background(BW.accentFill)
    }
}

/// `.vm-table tbody tr`: zebra background and hairline under each row.
public struct BWTableRowModifier: ViewModifier {
    let index: Int
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, BWMetrics.s3).padding(.vertical, 10)
            .background(index.isMultiple(of: 2) ? BW.paper : BW.surfaceAlt)
            .overlay(alignment: .bottom) { Rectangle().fill(BW.border).frame(height: BWMetrics.hairline) }
    }
}
public extension View { func bwTableRow(index: Int) -> some View { modifier(BWTableRowModifier(index: index)) } }

/// One column of a table row or header: equal share of the width, one line, shrinking to fit before it would wrap
/// or clip. Rows put cells in `HStack(spacing: 0)` so they sit on the header's grid. Text stops growing at the
/// largest standard size: seven columns on a phone cannot hold accessibility sizes ("32.4 m" truncated at AX1).
public struct BWTableCellModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .lineLimit(1).minimumScaleFactor(0.5)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.trailing, BWMetrics.s1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
public extension View { func bwTableCell() -> some View { modifier(BWTableCellModifier()) } }

// MARK: Ink panel

/// Black panel with faint circular rings and white text, black in both appearances (timer readout, round complete).
/// In dark mode a faint white edge keeps it apart from the black page.
public struct BWInkPanel<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content
            .foregroundStyle(BW.onPanel)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    BW.panel
                    Circle().strokeBorder(BW.panelOverlay(0.08), lineWidth: 1).frame(width: 450, height: 450).offset(x: 180, y: -180)
                    Circle().strokeBorder(BW.panelOverlay(0.05), lineWidth: 1).frame(width: 350, height: 350).offset(x: -160, y: 160)
                }
            }
            // clip the panel, not the ring stack: the 450 pt rings must not paint ink outside the panel's own frame
            .clipShape(RoundedRectangle(cornerRadius: BWMetrics.radiusLG, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: BWMetrics.radiusLG, style: .continuous).strokeBorder(BW.panelBorder, lineWidth: BWMetrics.hairline))
            .bwShadow(.card)
    }
}

// MARK: Preview

#Preview("TrapDesign") {
    ScrollView {
        VStack(alignment: .leading, spacing: BWMetrics.s4) {
            BWInkPanel {
                VStack(alignment: .leading, spacing: BWMetrics.s2) {
                    Text("TrapShooterPro").font(BWFont.display(.title)).textCase(.uppercase).tracking(BWTracking.brand)
                    Text("Olympic Trap · Shot timer").font(BWFont.value(.caption, weight: .regular)).opacity(0.55)
                }
                .padding(BWMetrics.s6)
            }
            .clipShape(RoundedRectangle(cornerRadius: BWMetrics.radiusLG, style: .continuous))

            BWSectionLabel("Round 20261022-0930-MT") { BWPill("Training", uppercase: true) }
            HStack(spacing: BWMetrics.s3) {
                BWKPITile("Score", value: "22", unit: "/25", sub: "88.0%")
                BWKPITile("1st shot", value: "0.684", unit: "s", sub: "average")
            }
            ViewThatFits {                                                 // one row, or a column at large text sizes
                HStack(spacing: BWMetrics.s2) { previewPills }
                VStack(alignment: .leading, spacing: BWMetrics.s2) { previewPills }
            }
            VStack(spacing: 0) {
                BWTableHeader(["#", "Stn", "Dir", "Result", "1st s"])
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 0) {
                        ForEach(Array(["\(i + 1)", "\(i + 1)", "L", "G", "0.6\(i)"].enumerated()), id: \.offset) { _, c in
                            Text(c).font(BWFont.value(.caption)).bwTableCell()
                        }
                    }
                    .bwTableRow(index: i)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: BWMetrics.radiusMD, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: BWMetrics.radiusMD, style: .continuous).strokeBorder(BW.border, lineWidth: BWMetrics.stroke))

            Text("0.000").font(BWFont.readout()).foregroundStyle(BW.ink).frame(maxWidth: .infinity).bwCard()
            VStack(alignment: .leading, spacing: BWMetrics.s3) {
                BWCardTitle("Range data")
                BWField("Place", value: "Capri Range")
                BWField("Session id", value: "20261022-0930-MT", mono: true)
            }
            .bwCard()
            Button("Start shot timer") {}.buttonStyle(.bwPrimary)
            Button("Share round") {}.buttonStyle(.bwSecondary)
            Button("NO TARGET") {}.buttonStyle(.bwDestructive)
        }
        .padding(BWMetrics.gutter)
    }
    .background(BW.surface)
}

@ViewBuilder private var previewPills: some View {
    BWPill("Hit 1st", status: BW.hitFirst, dot: true)
    BWPill("Hit 2nd", status: BW.hitSecond, dot: true)
    BWPill("Lost", status: BW.lost, dot: true)
    BWPill("Armed", status: BW.accentStatus)
}
