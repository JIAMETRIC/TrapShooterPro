import SwiftUI
import XCTest
import TrapCore
import TrapDesign
@testable import TrapApp

final class TrapAppTests: XCTestCase {
    func testSectionsInTabOrder() {
        XCTAssertEqual(AppSection.allCases.map(\.title), ["Home", "Record", "Timer", "Rounds", "Analysis", "Schemes", "Settings"])
    }

    /// Record + Timer and Rounds split beside the sidebar only when the master column gets a phone's width.
    /// Widths are the detail column: window minus sidebar (180 pt below 1100, 220 pt above).
    @MainActor
    func testAdaptiveSplitNeedsAPhoneWidthMasterColumn() {
        typealias Split = AdaptiveSplit<EmptyView, EmptyView>
        XCTAssertFalse(Split.splits(width: 744 - 180, breakpoint: Breakpoint(width: 744)), "iPad mini portrait")
        XCTAssertFalse(Split.splits(width: 1032 - 180, breakpoint: Breakpoint(width: 1032)), "13-inch portrait")
        XCTAssertTrue(Split.splits(width: 1376 - 220, breakpoint: Breakpoint(width: 1376)), "13-inch landscape")
        XCTAssertFalse(Split.splits(width: 393, breakpoint: Breakpoint(width: 393)), "phone")
    }
}

@MainActor
final class DemoModeTests: XCTestCase {
    func testSampleRoundsObeyTheRules() {
        let rounds = DemoMode.sampleRounds()
        XCTAssertEqual(rounds.count, 15)
        for r in rounds { XCTAssertEqual(Validation.issues(in: r), [], r.id) }
        XCTAssertEqual(rounds.filter(\.isComplete).count, 14)
        XCTAssertEqual(rounds.last?.recorded, 12, "one round in progress")
        XCTAssertEqual(DemoMode.sampleRounds().map(\.score), rounds.map(\.score), "the same rounds every run")
    }

    func testDemoAppOpensTheRoundInProgress() {
        let app = DemoMode.makeApp()
        XCTAssertEqual(app.record.round.id, "demo14")
        XCTAssertEqual(app.record.session.index, 12)
        XCTAssertEqual(app.record.session.phase, .recording)
    }
}
