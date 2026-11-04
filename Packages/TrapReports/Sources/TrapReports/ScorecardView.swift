import SwiftUI
import TrapCore
import TrapDesign

/// The A4 scorecard (595 × 842 pt), same content and order as the 7.0.7 report: header band, shooter and gun,
/// score, details band, 25-target strip, counts, target table, footer. Drawn with the design system (brand blue,
/// Inter and Bebas Neue) on a white page in light appearance; rendered to PNG by `ScorecardImageExporter` and to
/// vector PDF by `ScorecardPDFExporter`.
public struct ScorecardView: View {
    public static let pageSize = CGSize(width: 595, height: 842)
    let round: Round
    let breakModel: BreakDistanceModel
    let appVersion: String
    let today: String

    public init(round: Round, breakModel: BreakDistanceModel, appVersion: String, today: String = DateText.day(Date())) {
        self.round = round; self.breakModel = breakModel; self.appVersion = appVersion; self.today = today
    }

    private var timing: Bool { (0..<Round.targetCount).contains { round.firstShot[$0] != nil || round.secondShot[$0] != nil } }
    private var showBreak: Bool { timing && breakModel.settings.enabled }
    // A printed page: white paper whatever the appearance; brand deep blue for the bands (white text at 5.7:1).
    private let paper = Color.white, ink = Color.black, muted = BW.brandGrey, band = Color(hex: 0xF3F3F3), line = Color(hex: 0xE2E1E1)
    private let brand = BW.brandBlueDeep

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 14) {
                shooterAndScore
                detailsBand
                strip
                countsLine
                table
            }
            .padding(.horizontal, 30)
            .padding(.top, 18)
            Spacer(minLength: 0)
            Text("Created with TrapShooterPro Ver \(appVersion)  ·  \(today)")
                .font(BWFont.inter(fixed: 8)).foregroundStyle(muted)
                .frame(maxWidth: .infinity).padding(.bottom, 10)
        }
        .frame(width: ScorecardView.pageSize.width, height: ScorecardView.pageSize.height, alignment: .top)
        .background(paper)
        .environment(\.colorScheme, .light)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TRAPSHOOTERPRO").font(BWFont.numeric(fixed: 30)).tracking(1.5)
                Text("Ver \(appVersion)  ·  Olympic Trap").font(BWFont.inter(fixed: 9)).opacity(0.7)
            }
            Spacer()
            Text("SCORECARD").font(BWFont.numeric(fixed: 20)).tracking(1)
        }
        .foregroundStyle(paper)
        .padding(.horizontal, 30).frame(height: 68)
        .frame(maxWidth: .infinity).background(brand)
    }

    private var shooterAndScore: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(round.shooter.isEmpty ? "Shooter" : round.shooter).font(BWFont.inter(fixed: 22, weight: .semibold)).foregroundStyle(ink).lineLimit(1)
                Text([round.weapon, round.ammo].filter { !$0.isEmpty }.joined(separator: "  ·  ")).font(BWFont.inter(fixed: 10)).foregroundStyle(muted)
                if !round.choke1.isEmpty || !round.choke2.isEmpty {
                    Text("Choke   1st barrel: \(round.choke1.isEmpty ? "–" : round.choke1)    2nd barrel: \(round.choke2.isEmpty ? "–" : round.choke2)").font(BWFont.inter(fixed: 10)).foregroundStyle(muted)
                }
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(round.score)").font(BWFont.numeric(fixed: 76)).foregroundStyle(ink)
                Text("/25").font(BWFont.numeric(fixed: 24)).foregroundStyle(muted)
            }
        }
    }

    private var detailsBand: some View {
        let left: [(String, String)] = [("Session ID", round.sessionId), ("Date", round.date + (round.startTime.isEmpty ? "" : "  " + round.startTime)), ("Range", round.place), ("Field", round.field.map(String.init) ?? "")]
        let right: [(String, String)] = [("Scheme", "Scheme \(round.scheme)"), ("Type", round.type), ("First station", "\(round.startStation)"), ("Conditions", ScorecardView.conditions(round))]
        return HStack(alignment: .top, spacing: 16) {
            column(left); column(right)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(band)
    }

    private func column(_ rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(row.0.uppercased()).font(BWFont.inter(fixed: 8, weight: .semibold)).tracking(0.5).foregroundStyle(muted).frame(width: 72, alignment: .leading)
                    Text(row.1).font(BWFont.inter(fixed: 10, weight: .medium)).foregroundStyle(ink).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func color(_ r: TargetResult?) -> Color {
        switch r { case .hitFirst?: return BW.hitFirst.dot; case .hitSecond?: return BW.hitSecond.dot; case .lost?: return BW.lost.dot; case nil: return line }
    }
    private func arrow(_ d: Direction) -> String {
        switch d { case .left: return "arrow.up.left"; case .straight: return "arrow.up"; case .right: return "arrow.up.right" }
    }

    private var strip: some View {
        HStack(spacing: 2) {
            ForEach(0..<Round.targetCount, id: \.self) { i in
                VStack(spacing: 3) {
                    Group {
                        if let d = round.directions[i] { Image(systemName: arrow(d)).font(.system(size: 9, weight: .bold)) } else { Color.clear }
                    }
                    .frame(height: 10).foregroundStyle(ink)
                    Rectangle().fill(color(round.results[i])).frame(height: 30)
                    Text("\(round.station(at: i))").font(BWFont.inter(fixed: 8).monospacedDigit()).foregroundStyle(muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var countsLine: some View {
        let c = round.counts
        return HStack(spacing: 16) {
            legend(BW.hitFirst.dot, "\(c.hitFirst) first barrel")
            legend(BW.hitSecond.dot, "\(c.hitSecond) second barrel")
            legend(BW.lost.dot, "\(c.lost) miss")
            Spacer()
            Text("\(round.recorded) of 25 recorded").font(BWFont.inter(fixed: 10, weight: .medium)).foregroundStyle(muted)
        }
    }
    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) { Circle().fill(color).frame(width: 8, height: 8); Text(text).font(BWFont.inter(fixed: 10, weight: .medium)).foregroundStyle(ink) }
    }

    private var columns: [(String, CGFloat, Alignment)] {
        var c: [(String, CGFloat, Alignment)] = [("#", 22, .trailing), ("STN", 28, .trailing), ("DIR", 28, .center), ("TRAP", 36, .leading), ("ANGLE", 50, .leading), ("HEIGHT", 50, .trailing), ("RESULT", 78, .leading)]
        if timing { c += [("1ST SHOT S", 58, .trailing), ("2ND SHOT S", 58, .trailing)] }
        if showBreak { c.append(("BREAK M", 52, .trailing)) }
        return c
    }

    private var table: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, col in
                    Text(col.0).font(BWFont.inter(fixed: 8, weight: .semibold)).frame(width: col.1, alignment: col.2)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(paper).padding(.horizontal, 6).frame(height: 18).background(brand)
            ForEach(0..<Round.targetCount, id: \.self) { i in
                row(i).background(i % 2 == 1 ? band : paper)
            }
        }
        .overlay(Rectangle().strokeBorder(line, lineWidth: 0.5))
    }

    private func row(_ i: Int) -> some View {
        let t = round.machine(at: i), res = round.results[i]
        let brk = showBreak ? round.breakDistance(at: i, model: breakModel) : nil
        return HStack(spacing: 6) {
            cell("\(i + 1)", 22, .trailing, mono: true)
            cell("\(round.station(at: i))", 28, .trailing, mono: true)
            Group { if let d = round.directions[i] { Image(systemName: arrow(d)).font(.system(size: 9, weight: .bold)).foregroundStyle(ink) } else { Text("") } }.frame(width: 28)
            cell(t.map { "T\($0.number)" } ?? "–", 36, .leading, mono: true)
            cell(t?.label ?? "–", 50, .leading, mono: true)
            cell(t.map { String(format: "%.2f m", $0.height) } ?? "–", 50, .trailing, mono: true)
            HStack(spacing: 4) {
                if let res { Circle().fill(color(res)).frame(width: 7, height: 7); Text(res == .hitFirst ? "1st barrel" : res == .hitSecond ? "2nd barrel" : "Miss").font(BWFont.inter(fixed: 9, weight: .medium)) }
            }
            .frame(width: 78, alignment: .leading).foregroundStyle(ink)
            if timing {
                cell(round.firstShot[i].map { String(format: "%.3f", $0) } ?? "", 58, .trailing, mono: true)
                cell(round.secondShot[i].map { String(format: "%.3f", $0) } ?? "", 58, .trailing, mono: true)
            }
            if showBreak { cell(brk.map { String(format: "%.1f", $0) } ?? "", 52, .trailing, mono: true) }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6).frame(height: 17)
    }

    private func cell(_ s: String, _ w: CGFloat, _ a: Alignment, mono: Bool) -> some View {
        Text(s).font(mono ? BWFont.inter(fixed: 9).monospacedDigit() : BWFont.inter(fixed: 9)).foregroundStyle(ink).frame(width: w, alignment: a).lineLimit(1)
    }

    /// "Sun, 24°C, 55% humidity, light wind" (the report's condition line).
    public static func conditions(_ r: Round) -> String {
        var bits: [String] = []
        if let sky = Sky(rawValue: r.sky) { bits.append(sky.name) }
        if let t = r.temperature { bits.append("\(Int(t))°C") }
        if let h = r.humidity { bits.append("\(Int(h))% humidity") }
        if let w = Wind(rawValue: r.wind) { bits.append("\(w.name.lowercased()) wind") }
        return bits.joined(separator: ", ")
    }
}
