import SwiftUI
import TrapCore
import TrapDesign
import TrapPlatform

/// Home: the athlete dashboard (CLAY NOVA screen 06). Who is signed in and the round in progress, the main actions, then
/// the latest score, best, hit rate, rolling averages, stations, schemes and recent rounds for the chosen period.
/// Loads every round like Analysis does (CLAUDE.md rule 14) and computes off the view in `HomeStats`.
@MainActor
struct HomeScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.breakpoint) private var breakpoint
    @AppStorage(AppState.sectionKey) private var section = AppSection.home.rawValue
    @AppStorage("home.period") private var period = HomePeriod.month
    @AppStorage("home.type") private var type = HomeTypeFilter.all
    @State private var rounds: [Round] = []
    @State private var loaded = false

    var body: some View {
        let stats = HomeStats.make(rounds, period: period, type: type)
        ScreenScroll(title: "Home") {
            IdentityCard()
            Actions(go: go)
            Filters(period: $period, type: $type)
            if loaded && stats.rounds == 0 {
                Text(rounds.isEmpty ? "No rounds yet. Start training to see your scores here."
                                    : "No rounds in the last \(period.spoken). Choose a longer period.")
                    .font(BWFont.secondary).foregroundStyle(BW.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bwCard()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BWMetrics.s3), count: breakpoint.tileColumns),
                          spacing: BWMetrics.s3) {
                    BWKPITile("Latest", value: stats.latestScore.map(String.init) ?? "–", sub: stats.latestDate ?? "no full round")
                    BWKPITile("Personal best", value: stats.personalBest.map(String.init) ?? "–", sub: "of 25")
                    BWKPITile("Hit rate", value: stats.hitRateText, sub: "\(stats.targets) targets")
                    ForEach(HomeStats.windows, id: \.self) { n in
                        BWKPITile("Last \(n)", value: stats.lastAverages[n].map { JSText.fixed($0, 1) } ?? "–",
                                  sub: stats.lastAverages[n] == nil ? "needs \(n) rounds" : "average of 25")
                    }
                }
                StationCard(lines: stats.stations) { go(.analysis) }
                SchemeCard(lines: stats.schemes)
                RecentCard(rounds: stats.recent) { go(.rounds) }
            }
        }
        .task(id: app.libraryVersion) { load() }
        .onChange(of: app.record.round.recorded) { _, _ in load() }
    }

    private func load() {
        rounds = (try? TrapLog.measure("home load") { try app.repository.fetchAll() }) ?? []
        loaded = true
    }

    private func go(_ s: AppSection) { section = s.rawValue }
}

/// Greeting, avatar, role and the round in progress.
@MainActor
private struct IdentityCard: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let account = app.auth.account
        let round = app.record.round
        HStack(alignment: .center, spacing: BWMetrics.s4) {
            Text(account?.initials ?? Account.initials(of: app.settings.profile.name))
                .font(BWFont.display(size: 28)).foregroundStyle(BW.onAccent)
                .frame(width: 64, height: 64)
                .background(BW.accentFill, in: Circle())
                .overlay(Circle().strokeBorder(BW.glassBorder, lineWidth: BWMetrics.rule))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: BWMetrics.s1) {
                Text(Self.greeting()).font(BWFont.secondary).foregroundStyle(BW.textSecondary)
                Text(account?.firstName ?? Self.firstWord(app.settings.profile.name)).bwDisplay(.title).foregroundStyle(BW.text)
                    .lineLimit(1).minimumScaleFactor(0.6)
                HStack(spacing: BWMetrics.s2) {
                    if let account {
                        BWPill(account.role.title, status: BW.accentStatus, uppercase: true)
                    } else {
                        BWPill("No account", status: BW.neutral, uppercase: true)
                    }
                    if let r = account?.requestedRole {
                        BWPill("\(r.title) pending", status: BW.warning, dot: true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .bwCard()
        .bwAccentLeading()
        if round.hasData && !round.isComplete {
            HStack(spacing: BWMetrics.s2) {
                BWStatusDot(BW.warning.dot)
                Text("Round in progress · \(round.recorded) of \(Round.targetCount) targets · score \(round.score)")
                    .font(BWFont.secondary).foregroundStyle(BW.text)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// The first word of the Settings name, or "Shooter" when there is none.
    static func firstWord(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? "Shooter"
    }

    static func greeting(now: Date = Date(), calendar: Calendar = .current) -> String {
        let h = calendar.component(.hour, from: now)
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }
}

/// Start or continue, then Analysis and Rounds.
@MainActor
private struct Actions: View {
    @Environment(AppModel.self) private var app
    let go: (AppSection) -> Void

    var body: some View {
        let round = app.record.round
        let inProgress = round.hasData && !round.isComplete
        VStack(spacing: BWMetrics.s2) {
            Button {
                if round.isComplete { app.record.newRound() }
                go(.record)
            } label: {
                Label(inProgress ? "Continue round" : "Start training", systemImage: inProgress ? "play.fill" : "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bwPrimary)
            .accessibilityIdentifier("home.start")
            HStack(spacing: BWMetrics.s2) {
                Button { go(.analysis) } label: { Text("View analytics").frame(maxWidth: .infinity) }
                    .buttonStyle(.bwSecondary)
                Button { go(.rounds) } label: { Text("Latest session").frame(maxWidth: .infinity) }
                    .buttonStyle(.bwSecondary)
            }
        }
    }
}

@MainActor
private struct Filters: View {
    @Binding var period: HomePeriod
    @Binding var type: HomeTypeFilter

    var body: some View {
        VStack(alignment: .leading, spacing: BWMetrics.s2) {
            BWSectionLabel("Performance") {
                Menu {
                    Picker("Type", selection: $type) {
                        ForEach(HomeTypeFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Label(type.rawValue, systemImage: "line.3.horizontal.decrease")
                        .frame(minHeight: BWMetrics.actionHeight)
                }
                .font(BWFont.secondary.weight(.semibold))
                .accessibilityLabel("Round type, \(type.rawValue)")
            }
            Picker("Period", selection: $period) {
                ForEach(HomePeriod.allCases) { Text($0.rawValue).tag($0).accessibilityLabel($0.spoken) }
            }
            .pickerStyle(.segmented)
        }
    }
}

/// Hit rate per station as bars, the weakest marked.
@MainActor
private struct StationCard: View {
    let lines: [HomeStats.StationLine]
    let open: () -> Void

    var body: some View {
        // the weakest station is marked only when there is more than one to compare
        let rated = lines.filter { $0.targets > 0 }
        let weakest = rated.count > 1 ? rated.min { $0.rate < $1.rate }?.station : nil
        VStack(alignment: .leading, spacing: BWMetrics.s3) {
            BWSectionLabel("Stations") {
                Button("Details", action: open).font(BWFont.secondary.weight(.semibold))
            }
            ForEach(lines, id: \.station) { l in
                HStack(spacing: BWMetrics.s3) {
                    Text("\(l.station)").font(BWFont.value(.body)).foregroundStyle(BW.text).frame(width: 20)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(BW.surfaceAlt)
                            Capsule().fill(l.station == weakest ? BW.warning.dot : BW.accent)
                                .frame(width: max(0, g.size.width * l.rate))
                        }
                    }
                    .frame(height: 10)
                    Text(Analysis.percent(l.hits, l.targets))
                        .font(BWFont.value(.footnote, weight: .regular)).foregroundStyle(BW.textSecondary)
                        .frame(minWidth: 52, alignment: .trailing)
                }
                .frame(minHeight: 28)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Station \(l.station): \(Analysis.percent(l.hits, l.targets)) of \(l.targets) targets\(l.station == weakest ? ", weakest" : "")")
            }
        }
        .bwCard()
    }
}

/// Rounds, average and hit rate per scheme.
@MainActor
private struct SchemeCard: View {
    let lines: [HomeStats.SchemeLine]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BWSectionLabel("Schemes").padding(.bottom, BWMetrics.s2)
            BWTableHeader(["Scheme", "Rounds", "Avg", "Hit"])
            ForEach(Array(lines.enumerated()), id: \.offset) { k, l in
                HStack(spacing: 0) {
                    cell("\(l.scheme)"); cell("\(l.rounds)")
                    cell(l.averageScore.map { JSText.fixed($0, 1) } ?? "–"); cell(Analysis.percent(l.hits, l.targets))
                }
                .padding(.vertical, BWMetrics.s2)
                .bwTableRow(index: k)
            }
        }
        .bwCard()
    }
    private func cell(_ t: String) -> some View { Text(t).font(BWFont.value(.footnote, weight: .regular)).bwTableCell() }
}

/// The five newest rounds.
@MainActor
private struct RecentCard: View {
    let rounds: [Round]
    let open: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: BWMetrics.s2) {
            BWSectionLabel("Recent rounds") {
                Button("View all", action: open).font(BWFont.secondary.weight(.semibold))
            }
            ForEach(rounds, id: \.id) { r in
                HStack(alignment: .center, spacing: BWMetrics.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.place.isEmpty ? "Round" : r.place).font(BWFont.body.weight(.semibold)).foregroundStyle(BW.text)
                            .lineLimit(1)
                        Text("\(r.date) · Scheme \(r.scheme) · \(r.type)").font(BWFont.note).foregroundStyle(BW.textSecondary)
                    }
                    Spacer(minLength: BWMetrics.s2)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(r.score)").font(BWFont.value(.title2)).foregroundStyle(BW.ink)
                        Text(r.recorded == Round.targetCount ? "of 25" : "\(r.recorded) of 25")
                            .font(BWFont.note).foregroundStyle(BW.textMuted)
                    }
                }
                .frame(minHeight: BWMetrics.actionHeight)
                .accessibilityElement(children: .combine)
                if r.id != rounds.last?.id { Divider().overlay(BW.border) }
            }
        }
        .bwCard()
    }
}
