import SwiftUI
import TrapCore
import TrapDesign

extension TargetResult {
    /// Button and ledger text.
    var title: String {
        switch self { case .hitFirst: return "Hit 1st"; case .hitSecond: return "Hit 2nd"; case .lost: return "Lost" }
    }
    var status: BW.Status {
        switch self { case .hitFirst: return BW.hitFirst; case .hitSecond: return BW.hitSecond; case .lost: return BW.lost }
    }
}

/// Seconds as the page shows them: "0.613".
func secondsText(_ v: Double?) -> String { v.map { JSText.fixed($0, 3) } ?? "–" }

/// The 25 targets in one strip, coloured by result; the current target is outlined. Tap to go to a target.
@MainActor
struct ScoreStrip: View {
    let round: Round
    var current: Int?
    var onSelect: ((Int) -> Void)?
    @Environment(\.breakpoint) private var breakpoint

    /// Height of a drawn tile; the tap area around it is the full touch target.
    private let tileHeight: CGFloat = 28

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<Round.targetCount, id: \.self) { i in
                let r = round.results[i]
                Button { onSelect?(i) } label: {
                    Text(round.directions[i]?.rawValue ?? "")
                        .font(BWFont.label)
                        .lineLimit(1).minimumScaleFactor(0.5)              // 25 tiles in a row: the letter must fit
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .foregroundStyle(r?.status.foreground ?? BW.textMuted)
                        .frame(maxWidth: .infinity, minHeight: tileHeight)
                        .background(r?.status.background ?? BW.surfaceAlt, in: RoundedRectangle(cornerRadius: BWMetrics.radiusXS))
                        .overlay(RoundedRectangle(cornerRadius: BWMetrics.radiusXS).stroke(i == current ? BW.accent : (r?.status.border ?? BW.border), lineWidth: i == current ? BWMetrics.rule : BWMetrics.hairline))
                        .padding(.vertical, max(0, (breakpoint.minTouchTarget - tileHeight) / 2))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(onSelect == nil)
                .accessibilityLabel("Target \(i + 1), \(round.directions[i]?.name ?? "no direction"), \(r?.title ?? "no result")")
            }
        }
    }
}

/// A line of feedback: errors in the danger colour with their recovery, notes in secondary text. Never an alert.
@MainActor
struct MessageLine: View {
    var error: DisplayError?
    var note: String?
    var body: some View {
        if let e = error {
            Text(e.text).font(BWFont.secondary).foregroundStyle(BW.danger.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(BWMetrics.s3)
                .background(BW.danger.background, in: RoundedRectangle(cornerRadius: BWMetrics.radiusMD))
        } else if let n = note, !n.isEmpty {
            Text(n).font(BWFont.secondary).foregroundStyle(BW.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Screen background and padding shared by every place.
@MainActor
struct ScreenScroll<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BWMetrics.s4) { content }
                .padding(BWMetrics.gutter)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
        }
        .background(BW.surface)
        .navigationTitle(title)
    }
}
