import SwiftUI

/// One place in `BWBottomNav`.
public struct BWNavItem<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: String
    /// SF Symbol name; drawn in its `.fill` variant.
    public let symbol: String
    public init(_ id: ID, title: String, symbol: String) {
        self.id = id; self.title = title; self.symbol = symbol
    }
}

/// The theme's bottom navigation (`AppBottomNav`): a 16 pt frosted glass bar with the blue `card` shadow. Each item is an icon
/// over a label in `BW.tint`; the selected one sits on a 14 pt deep-blue tile in white. Items in `more` share the last
/// slot, a menu that takes the selected item's icon and title while one of them is open.
public struct BWBottomNav<ID: Hashable>: View {
    let items: [BWNavItem<ID>]
    let more: [BWNavItem<ID>]
    @Binding var selection: ID

    public init(items: [BWNavItem<ID>], more: [BWNavItem<ID>] = [], selection: Binding<ID>) {
        self.items = items; self.more = more; _selection = selection
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: BWMetrics.radiusLG, style: .continuous)
        HStack(spacing: BWMetrics.s1) {
            ForEach(items) { item in
                Button { selection = item.id } label: {
                    BWNavLabel(title: item.title, symbol: item.symbol, selected: selection == item.id)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selection == item.id ? .isSelected : [])
                .accessibilityIdentifier("nav.\(item.title.lowercased())")
            }
            if !more.isEmpty {
                let open = more.first { $0.id == selection }
                Menu {
                    ForEach(more) { item in
                        Button { selection = item.id } label: { Label(item.title, systemImage: item.symbol) }
                    }
                } label: {
                    BWNavLabel(title: open?.title ?? "More", symbol: open?.symbol ?? "ellipsis", selected: open != nil)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(open.map { "More, \($0.title)" } ?? "More")
                .accessibilityAddTraits(open != nil ? .isSelected : [])
                .accessibilityIdentifier("nav.more")
            }
        }
        .padding(BWMetrics.s1 + 2)
        .background {
            // the theme's iOS glass: frosted backdrop under the white fill, so content scrolling behind stays unread
            shape.fill(.regularMaterial)
            shape.fill(BW.navFill)
        }
        .overlay(shape.strokeBorder(BW.glassBorder, lineWidth: BWMetrics.hairline))
        .bwShadow(.card)
        // a tab bar does not grow with the text size; the large content viewer shows the item instead
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

/// Icon over label; deep-blue tile with white content when selected.
private struct BWNavLabel: View {
    let title: String, symbol: String, selected: Bool
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol).symbolVariant(.fill)
                .font(BWFont.inter(.title3, weight: .medium))
                .frame(height: 24)
            Text(title)
                .font(BWFont.inter(.caption2, weight: selected ? .semibold : .medium))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(selected ? BW.onAccent : BW.tint)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background {
            if selected {
                RoundedRectangle(cornerRadius: BWMetrics.radiusItem, style: .continuous).fill(BW.accentFill).bwShadow(.control)
            }
        }
        .contentShape(Rectangle())
        .accessibilityShowsLargeContentViewer { Label(title, systemImage: symbol) }
        .animation(BWMotion.fast, value: selected)
    }
}
