import Foundation
import TrapCore

/// The period filter of Home.
enum HomePeriod: String, CaseIterable, Identifiable, Sendable {
    case week = "7D", month = "30D", quarter = "90D", year = "12M", all = "All"
    var id: String { rawValue }
    var days: Int? {
        switch self { case .week: return 7; case .month: return 30; case .quarter: return 90; case .year: return 365; case .all: return nil }
    }
    var spoken: String {
        switch self { case .week: return "7 days"; case .month: return "30 days"; case .quarter: return "90 days"; case .year: return "12 months"; case .all: return "all time" }
    }
}

/// Training, competition or both.
enum HomeTypeFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All", training = "Training", competition = "Competition"
    var id: String { rawValue }
    func matches(_ r: Round) -> Bool { self == .all || r.type == rawValue }
}

/// What the athlete home dashboard shows (CLAY NOVA screen 06), from the rounds in the chosen period and type.
/// Scores, averages and the best round count full rounds only, as Analysis does; hit rates count every recorded target.
struct HomeStats: Equatable {
    struct StationLine: Equatable {
        let station: Int, hits: Int, targets: Int
        /// Hits over targets, 0 with no targets.
        var rate: Double { targets > 0 ? Double(hits) / Double(targets) : 0 }
    }
    struct SchemeLine: Equatable { let scheme: Int, rounds: Int, averageScore: Double?, hits: Int, targets: Int }

    var rounds = 0
    var latestScore: Int?
    var latestDate: String?
    var personalBest: Int?
    var hits = 0
    var targets = 0
    /// Average score of the last 5, 10 and 20 full rounds; nil when there are fewer.
    var lastAverages: [Int: Double] = [:]
    var stations: [StationLine] = []
    var schemes: [SchemeLine] = []
    /// Newest first, at most five.
    var recent: [Round] = []

    var hitRateText: String { Analysis.percent(hits, targets) }
    static let windows = [5, 10, 20]

    static func make(_ all: [Round], period: HomePeriod, type: HomeTypeFilter, now: Date = Date(),
                     calendar: Calendar = .current) -> HomeStats {
        let from = period.days.flatMap { calendar.date(byAdding: .day, value: -$0, to: now) }.map(DateText.day)
        let list = all
            .filter { r in r.recorded > 0 && type.matches(r) && (from.map { r.date >= $0 } ?? true) }
            .sorted { ($0.date, $0.createdAt) > ($1.date, $1.createdAt) }
        var s = HomeStats()
        s.rounds = list.count
        s.recent = Array(list.prefix(5))
        let full = list.filter { $0.recorded == Round.targetCount }
        s.latestScore = full.first?.score
        s.latestDate = full.first?.date
        s.personalBest = full.map(\.score).max()
        for n in windows where full.count >= n {
            s.lastAverages[n] = averageScore(full.prefix(n))
        }

        var stationHits = Array(repeating: 0, count: Round.stationCount), stationTargets = stationHits
        for r in list {
            for i in 0..<Round.targetCount {
                guard let res = r.results[i] else { continue }
                let k = r.stationIndex(at: i)
                stationTargets[k] += 1
                if res.isHit { stationHits[k] += 1; s.hits += 1 }
                s.targets += 1
            }
        }
        s.stations = (0..<Round.stationCount).map { StationLine(station: $0 + 1, hits: stationHits[$0], targets: stationTargets[$0]) }

        s.schemes = Dictionary(grouping: list, by: \.scheme).keys.sorted().map { n in
            let rs = list.filter { $0.scheme == n }
            let fs = rs.filter { $0.recorded == Round.targetCount }
            let st = Analysis.stats(rs)
            return SchemeLine(scheme: n, rounds: rs.count,
                              averageScore: averageScore(fs),
                              hits: st.hits, targets: st.targets)
        }
        return s
    }

    /// Mean score, nil for no rounds.
    private static func averageScore<C: Collection>(_ rounds: C) -> Double? where C.Element == Round {
        rounds.isEmpty ? nil : Double(rounds.reduce(0) { $0 + $1.score }) / Double(rounds.count)
    }
}
