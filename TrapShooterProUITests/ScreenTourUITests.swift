import XCTest

/// Walks every screen, sheet and dialog in demo mode, flow by flow, and writes one PNG per screen to
/// `$SCREENS_DIR/<flow>/<nn>-<screen>.png`. Skipped unless SCREENS_DIR is set, so CI runs are unaffected.
/// Run: `TEST_RUNNER_SCREENS_DIR=/abs/path xcodebuild test … -only-testing:TrapShooterProUITests/ScreenTourUITests`
final class ScreenTourUITests: XCTestCase {
    private var app: XCUIApplication!
    private var outDir: URL!
    private var flow = ""
    private var count = 0

    override func setUpWithError() throws {
        guard let dir = ProcessInfo.processInfo.environment["SCREENS_DIR"], !dir.isEmpty else {
            throw XCTSkip("SCREENS_DIR not set")
        }
        outDir = URL(fileURLWithPath: dir)
        continueAfterFailure = true
    }

    // MARK: flows (run in name order)

    func test01StartARound() {
        begin("01-Start-a-Round", section: "record")
        shot("record-round-in-progress")
        app.buttons["record.newRound"].tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == 'New round' AND identifier != 'record.newRound'")).firstMatch
        if confirm.waitForExistence(timeout: 3) {
            shot("new-round-confirmation")
            confirm.tap()
        }
        wait(1.5)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow While Using App"]
        if allow.waitForExistence(timeout: 3) {
            shot("location-permission")
            allow.tap(); wait(3)
        }
        shot("range-data-form")
        pickerMenu("Scheme", shotName: "scheme-picker")
        app.swipeUp(); wait(0.5)
        shot("conditions-form")
        pickerMenu("Sky", shotName: "sky-picker")
        tapButton("record.start")
        shot("missing-range-data-error")
        app.swipeDown(); app.swipeDown()
        let place = app.textFields["Range name"]
        if place.waitForExistence(timeout: 2) {
            place.tap(); wait(1)
            dismissKeyboardTip()
            place.typeText("Al Ain Shooting Club")
            shot("typing-range-name")
            dismissKeyboard()
        }
        choose("Field", "3"); choose("Sky", "Sun"); choose("Wind", "Calm")
        let temp = app.textFields["°C"], hum = app.textFields["%"]
        if temp.exists { temp.tap(); dismissKeyboardTip(); temp.typeText("28") }
        if hum.exists { hum.tap(); dismissKeyboardTip(); hum.typeText("45") }
        dismissKeyboard()
        shot("range-data-filled")
        tapButton("record.start")
        wait(1)
        shot("round-started-target-1")
        relaunch(section: "timer")
        shot("timer-before-round-start")
    }

    func test02RecordTargets() {
        begin("02-Record-Targets", section: "record")
        shot("entry-panel")
        tapFirstEnabled(["record.direction.left", "record.direction.right", "record.direction.straight"])
        shot("direction-chosen")
        tapButton("record.result.hitFirst")
        shot("result-entered-next-target")
        tapButton("record.noTarget")
        shot("no-target")
        tapButton("record.undo")
        shot("undo")
        app.swipeUp(); wait(0.5)
        shot("scorecard-strip")
        app.swipeUp(); wait(0.5)
        shot("target-ledger")
        app.swipeUp(); wait(0.5)
        shot("target-ledger-end")
        scrollToTop()
        if app.buttons["Range data"].exists {
            app.buttons["Range data"].tap(); wait(1)
            shot("edit-range-data")
            tapButton("record.start")
            wait(0.5)
        }
        // fill the rest of the round to reach the done card
        for _ in 0..<30 {
            guard app.buttons["record.result.hitFirst"].exists, !app.staticTexts["Round complete"].exists else { break }
            tapFirstEnabled(["record.direction.right", "record.direction.left", "record.direction.straight"], fail: false)
            tapButton(Bool.random() ? "record.result.hitFirst" : "record.result.hitSecond", fail: false)
        }
        scrollToTop()
        shot("round-complete")
        let share = shareButton
        if share.exists {
            share.tap(); wait(1)
            shot("share-format-menu")
            let pdf = app.buttons["PDF"]
            if pdf.exists {
                pdf.tap(); wait(4)
                shot("share-scorecard-pdf-sheet")
            }
        }
    }

    func test03Timer() {
        begin("03-Timer", section: "timer", scripted: true)
        shot("timer-ready")
        pickerMenu("Input", shotName: "microphone-picker")
        tapButton("timer.start")
        wait(0.3)
        shot("timer-listening")
        let readout = app.descendants(matching: .any)["timer.readout"].firstMatch
        _ = waitFor(readout, label: "First shot 0.612", timeout: 6)
        shot("shot-timed")
        app.swipeUp(); wait(0.5)
        shot("level-meter-and-audio-check")
        scrollToTop()
        if app.buttons["timer.stop"].exists { app.buttons["timer.stop"].tap(); wait(0.5) }
        shot("timer-stopped")
    }

    func test04Rounds() {
        begin("04-Rounds", section: "rounds")
        shot("rounds-list")
        menu("All schemes", shotName: "scheme-filter")
        menu("All types", shotName: "type-filter")
        let full = app.buttons["Full rounds"]
        if full.exists { full.tap(); wait(0.5); shot("full-rounds-only"); full.tap(); wait(0.5) }
        let search = app.searchFields.firstMatch
        if !search.exists { app.swipeDown(); wait(1) }
        if search.waitForExistence(timeout: 2) {
            search.tap(); search.typeText("Al Ain"); wait(1)
            shot("search")
            if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
            wait(0.5)
        }
        let rows = app.buttons.matching(NSPredicate(format: "label CONTAINS '-MT'"))
        let row = rows.element(boundBy: 1)
        if row.waitForExistence(timeout: 3) {
            row.swipeLeft(); wait(0.8)
            shot("swipe-to-delete")
            if app.buttons["Delete"].exists {
                app.buttons["Delete"].tap(); wait(0.8)
                shot("undo-delete")
                if app.buttons["Undo delete"].exists { app.buttons["Undo delete"].tap(); wait(0.5) }
            }
        }
        let open = rows.element(boundBy: 0)
        if open.exists {
            open.tap(); wait(1.5)
            shot("round-detail")
            app.swipeUp(); wait(0.5)
            shot("round-detail-scorecard")
            app.swipeUp(); wait(0.5)
            shot("round-detail-scorecard-end")
            scrollToTop()
            let share = shareButton
            if share.exists {
                share.tap(); wait(1)
                shot("share-format-menu")
                if app.buttons["Image"].exists {
                    app.buttons["Image"].tap(); wait(4)
                    shot("share-scorecard-image-sheet")
                }
            }
        }
    }

    func test05Analysis() {
        begin("05-Analysis", section: "analysis")
        scrollPages("analysis")
    }

    func test06Schemes() {
        begin("06-Schemes", section: "schemes")
        let more = app.buttons["nav.more"]                         // the bottom nav's More slot holds Schemes and Settings
        if more.waitForExistence(timeout: 3) {
            more.tap(); wait(1)
            shot("more-menu")
            let schemes = app.buttons["Schemes"].firstMatch
            if schemes.exists { schemes.tap() } else { closeMenu() }
            wait(1)
        }
        scrollPages("scheme-default")
        scrollToTop()
        for n in ["5", "9"] where app.buttons[n].exists {
            app.buttons[n].tap(); wait(0.5)
            shot("scheme-\(n)")
        }
    }

    func test07Settings() {
        begin("07-Settings", section: "settings")
        scrollPages("settings")
        scrollToTop()
        pickerMenu("Start signal", shotName: "start-signal-picker")
        pickerMenu("Shot size", shotName: "shot-size-picker")
        for (title, name) in [("Back up all rounds", "backup-share-sheet"), ("Export all rounds as CSV", "csv-export-share-sheet"),
                              ("Send diagnostics", "diagnostics-share-sheet")] {
            let b = app.buttons[title]
            scrollTo(b)
            guard b.exists else { continue }
            b.tap(); wait(5)
            shot(name)
            closeSheet()
        }
        let restore = app.buttons["Restore or import a backup"]
        scrollTo(restore)
        if restore.exists {
            restore.tap(); wait(5)
            shot("restore-file-picker")
            closeSheet()
        }
        let version = app.cells.containing(.staticText, identifier: "TrapShoot").firstMatch
        scrollTo(version)
        if version.exists {
            version.press(forDuration: 1.5); wait(2)
            shot("debug-screen")
        }
    }

    // MARK: helpers

    private func begin(_ name: String, section: String, scripted: Bool = false) {
        flow = name; count = 0
        try? FileManager.default.createDirectory(at: outDir.appendingPathComponent(flow), withIntermediateDirectories: true)
        app = XCUIApplication()
        relaunch(section: section, scripted: scripted)
    }

    private func relaunch(section: String, scripted: Bool = false) {
        app.terminate()
        app.launchArguments = ["-demo", "-state.section", section] + (scripted ? ["-uitest"] : [])
        app.launch()
        wait(2.5)
    }

    private func shot(_ name: String) {
        count += 1
        let file = outDir.appendingPathComponent(flow).appendingPathComponent(String(format: "%02d-%@.png", count, name))
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }

    private func wait(_ s: Double) { Thread.sleep(forTimeInterval: s) }

    private func waitFor(_ e: XCUIElement, label: String, timeout: Double) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end { if e.exists && e.label.contains(label) { return true }; wait(0.2) }
        return false
    }

    private func scrollToTop() {
        for _ in 0..<5 { app.swipeDown() }
        wait(0.4)
    }

    /// Screenshots a long screen page by page until the picture stops changing.
    private func scrollPages(_ name: String) {
        var last = Data()
        for page in 1...10 {
            wait(0.6)
            let png = XCUIScreen.main.screenshot().pngRepresentation
            if png == last { break }
            last = png
            shot(page == 1 ? name : "\(name)-\(page)")
            app.swipeUp()
        }
    }

    private func scrollTo(_ e: XCUIElement) {
        scrollToTop()
        var tries = 0
        while !(e.exists && e.isHittable) && tries < 10 { app.swipeUp(); tries += 1 }
    }

    private func tapButton(_ id: String, fail: Bool = true) {
        let b = app.buttons[id]
        var tries = 0
        while !(b.exists && b.isHittable) && tries < 6 { app.swipeUp(); tries += 1 }
        if b.exists && b.isHittable { b.tap(); wait(0.6) } else if fail { XCTFail("\(id) not on screen") }
    }

    private func tapFirstEnabled(_ ids: [String], fail: Bool = true) {
        for id in ids where app.buttons[id].exists && app.buttons[id].isEnabled { tapButton(id); return }
        if fail { XCTFail("no enabled button among \(ids)") }
    }

    /// Opens a menu-style Picker by its label, screenshots the open menu and closes it.
    private func pickerMenu(_ label: String, shotName: String) {
        guard openPicker(label) else { return }
        shot(shotName)
        closeMenu()
    }

    private var shareButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'share'")).firstMatch
    }

    /// Opens a menu-style Picker whose label starts with `label`, scrolling to it first.
    private func openPicker(_ label: String) -> Bool {
        let b = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", label)).firstMatch
        guard b.exists else { return false }
        if !b.isHittable { scrollTo(b) }
        b.tap(); wait(0.8)
        return true
    }

    private func menu(_ title: String, shotName: String) {
        let b = app.buttons[title]
        guard b.exists else { return }
        b.tap(); wait(0.8)
        shot(shotName)
        closeMenu()
    }

    private func choose(_ label: String, _ value: String) {
        guard openPicker(label) else { return }
        let option = app.buttons[value].firstMatch
        if option.exists { option.tap() } else { closeMenu() }
        wait(0.4)
    }

    private func closeMenu() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
        wait(0.6)
    }

    private func closeSheet() {
        for title in ["Close", "Cancel", "Done"] where app.buttons[title].exists { app.buttons[title].firstMatch.tap(); wait(1); return }
        app.swipeDown(velocity: .fast); wait(1)
    }

    /// The first-run keyboard tip ("Continue") covers the form on a fresh simulator.
    private func dismissKeyboardTip() {
        for a: XCUIApplication in [app!, XCUIApplication(bundleIdentifier: "com.apple.springboard")] where a.buttons["Continue"].exists {
            a.buttons["Continue"].tap(); wait(0.8)
        }
    }

    private func dismissKeyboard() {
        guard app.keyboards.count > 0 else { return }
        if app.keyboards.buttons["Return"].exists { app.keyboards.buttons["Return"].tap() }
        if app.keyboards.count > 0 { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap() }
        wait(0.5)
    }
}
