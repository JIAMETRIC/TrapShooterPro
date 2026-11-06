import XCTest
import TrapCore
import TrapPlatform
@testable import TrapApp

final class AuthRulesTests: XCTestCase {
    private let now = ISO8601DateFormatter().date(from: "2026-11-06T12:00:00Z") ?? Date()

    private func valid() -> Registration {
        var r = Registration()
        r.fullName = "  Sm   Yugan "
        r.email = " SMYugan@Example.com "
        r.mobile = "+91 98765-43210"
        r.country = "IN"
        r.dateOfBirth = Calendar.current.date(byAdding: .year, value: -20, to: now)
        r.password = "trap2026"
        r.confirmPassword = "trap2026"
        r.acceptedTerms = true
        return r
    }

    func testValidFormHasNoIssues() {
        XCTAssertEqual(AuthRules.issues(valid(), now: now), [])
    }

    func testCleaning() {
        XCTAssertEqual(AuthRules.cleanName("  Sm \t Yugan\u{0007} "), "Sm Yugan")
        XCTAssertEqual(AuthRules.cleanEmail(" A@B.Com "), "a@b.com")
        XCTAssertEqual(AuthRules.cleanMobile("+91 98765-43210"), "+919876543210")
    }

    func testEachRule() {
        var r = valid(); r.email = "not-an-email"
        XCTAssertEqual(AuthRules.issues(r, now: now), [.invalidEmail])
        r = valid(); r.mobile = "98765 43210"
        XCTAssertEqual(AuthRules.issues(r, now: now), [.invalidMobile])
        r = valid(); r.country = "XX1"
        XCTAssertEqual(AuthRules.issues(r, now: now), [.invalidCountry])
        r = valid(); r.dateOfBirth = Calendar.current.date(byAdding: .year, value: -10, to: now)
        XCTAssertEqual(AuthRules.issues(r, now: now), [.tooYoung(minimum: 13)])
        r = valid(); r.dateOfBirth = nil
        XCTAssertEqual(AuthRules.issues(r, now: now), [.missing("Date of birth")])
        r = valid(); r.password = "short1"; r.confirmPassword = "short1"
        XCTAssertEqual(AuthRules.issues(r, now: now), [.passwordTooShort(minimum: 8)])
        r = valid(); r.password = "onlyletters"; r.confirmPassword = "onlyletters"
        XCTAssertEqual(AuthRules.issues(r, now: now), [.passwordNeedsLetterAndDigit])
        r = valid(); r.confirmPassword = "trap2027"
        XCTAssertEqual(AuthRules.issues(r, now: now), [.passwordsDiffer])
        r = valid(); r.wantsCoachRole = true
        XCTAssertEqual(AuthRules.issues(r, now: now), [.invitationNeeded])
        r = valid(); r.invitationCode = "bad code!"
        XCTAssertEqual(AuthRules.issues(r, now: now), [.invalidInvitationCode])
        r = valid(); r.acceptedTerms = false
        XCTAssertEqual(AuthRules.issues(r, now: now), [.termsNotAccepted])
    }

    func testRegisterThenSignIn() async throws {
        let service = DeviceAuthService(store: MemorySecretStore(), iterations: 1_000)
        let a = try await service.register(valid(), now: now)
        XCTAssertEqual(a.email, "smyugan@example.com")
        XCTAssertEqual(a.fullName, "Sm Yugan")
        XCTAssertEqual(a.mobile, "+919876543210")
        XCTAssertEqual(a.role, .athlete)
        XCTAssertFalse(a.emailVerified)
        let b = try await service.signIn(email: "SMYUGAN@example.com ", password: "trap2026", now: now)
        XCTAssertEqual(a, b)
        do { _ = try await service.register(valid(), now: now); XCTFail("duplicate") } catch { XCTAssertEqual(error as? AuthError, .emailTaken) }
    }

    func testCoachRoleIsOnlyRequested() async throws {
        var r = valid(); r.wantsCoachRole = true; r.invitationCode = "CLUB-2026"
        let a = try await DeviceAuthService(store: MemorySecretStore(), iterations: 1_000).register(r, now: now)
        XCTAssertEqual(a.role, .athlete)
        XCTAssertEqual(a.requestedRole, .coach)
    }

    func testPasswordIsNotStoredInTheClear() async throws {
        let store = MemorySecretStore()
        _ = try await DeviceAuthService(store: store, iterations: 1_000).register(valid(), now: now)
        let blob = try XCTUnwrap(try store.data(for: DeviceAuthService.key))
        XCTAssertNil(String(data: blob, encoding: .utf8)?.range(of: "trap2026"))
    }

    func testWrongPasswordAndUnknownEmailLookTheSame() async throws {
        let service = DeviceAuthService(store: MemorySecretStore(), iterations: 1_000)
        _ = try await service.register(valid(), now: now)
        for email in ["smyugan@example.com", "nobody@example.com"] {
            do { _ = try await service.signIn(email: email, password: "wrong123", now: now); XCTFail() } catch {
                XCTAssertEqual(error as? AuthError, .wrongCredentials)
            }
        }
    }

    func testLockAfterFiveFailures() async throws {
        let service = DeviceAuthService(store: MemorySecretStore(), iterations: 1_000)
        _ = try await service.register(valid(), now: now)
        for _ in 0..<4 { _ = try? await service.signIn(email: "smyugan@example.com", password: "wrong123", now: now) }
        do { _ = try await service.signIn(email: "smyugan@example.com", password: "wrong123", now: now); XCTFail() } catch {
            XCTAssertEqual(error as? AuthError, .locked(seconds: 30))
        }
        // even the right password waits out the lock
        do { _ = try await service.signIn(email: "smyugan@example.com", password: "trap2026", now: now.addingTimeInterval(10)); XCTFail() } catch {
            XCTAssertEqual(error as? AuthError, .locked(seconds: 20))
        }
        let a = try await service.signIn(email: "smyugan@example.com", password: "trap2026", now: now.addingTimeInterval(31))
        XCTAssertEqual(a.email, "smyugan@example.com")
    }

    func testRemoveAccount() async throws {
        let service = DeviceAuthService(store: MemorySecretStore(), iterations: 1_000)
        let a = try await service.register(valid(), now: now)
        try await service.removeAccount(email: "SMYUGAN@example.com")
        let gone = try await service.account(id: a.id)
        XCTAssertNil(gone)
    }

    @MainActor
    func testModelKeepsTheSession() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "auth-test"))
        defaults.removePersistentDomain(forName: "auth-test")
        let service = DeviceAuthService(store: MemorySecretStore(), iterations: 1_000)
        let model = AuthModel(service: service, defaults: defaults, now: { self.now })
        XCTAssertEqual(model.state, .signedOut)
        let err = await model.register(valid())
        XCTAssertNil(err)
        XCTAssertNotNil(model.account)

        let reopened = AuthModel(service: service, defaults: defaults, now: { self.now })
        XCTAssertEqual(reopened.state, .restoring)
        await reopened.restore()
        XCTAssertEqual(reopened.account, model.account)

        reopened.signOut()
        XCTAssertEqual(reopened.state, .signedOut)
        XCTAssertNil(defaults.string(forKey: AuthModel.sessionKey))
    }

    /// Guideline 5.1.1: the app works without an account, and that choice survives a relaunch.
    @MainActor
    func testContinueWithoutAccount() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "auth-guest-test"))
        defaults.removePersistentDomain(forName: "auth-guest-test")
        let service = DeviceAuthService(store: MemorySecretStore(), iterations: 1_000)
        let model = AuthModel(service: service, defaults: defaults, now: { self.now })
        model.continueWithoutAccount()
        XCTAssertEqual(model.state, .guest)
        XCTAssertNil(model.account)
        XCTAssertEqual(AuthModel(service: service, defaults: defaults).state, .guest)

        // signing in later ends guest mode
        let err = await model.register(valid())
        XCTAssertNil(err)
        XCTAssertFalse(defaults.bool(forKey: AuthModel.guestKey))
        model.signOut()
        XCTAssertEqual(AuthModel(service: service, defaults: defaults).state, .signedOut)
    }

    /// Guideline 5.1.1(v): an account made in the app can be deleted in the app.
    @MainActor
    func testDeleteAccount() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "auth-delete-test"))
        defaults.removePersistentDomain(forName: "auth-delete-test")
        let service = DeviceAuthService(store: MemorySecretStore(), iterations: 1_000)
        let model = AuthModel(service: service, defaults: defaults, now: { self.now })
        _ = await model.register(valid())
        let id = try XCTUnwrap(model.account?.id)
        let err = await model.deleteAccount()
        XCTAssertNil(err)
        XCTAssertEqual(model.state, .signedOut)
        let gone = try await service.account(id: id)
        XCTAssertNil(gone)
        let again = await model.signIn(email: "smyugan@example.com", password: "trap2026")
        XCTAssertNotNil(again)                                             // the account is really gone
    }

    func testInitials() {
        XCTAssertEqual(Account.initials(of: "Mohammad Tajudeen Khan"), "MT")
        XCTAssertEqual(Account.initials(of: "  "), "?")
    }
}

final class HomeStatsTests: XCTestCase {
    private let now = ISO8601DateFormatter().date(from: "2026-11-06T12:00:00Z") ?? Date()

    func testDemoRounds() {
        let rounds = DemoMode.sampleRounds(now: now)
        let s = HomeStats.make(rounds, period: .all, type: .all, now: now)
        let full = rounds.filter { $0.recorded == Round.targetCount }
        XCTAssertEqual(s.rounds, 15)
        XCTAssertEqual(s.recent.count, 5)
        XCTAssertEqual(s.personalBest, full.map(\.score).max())
        XCTAssertEqual(s.stations.map(\.station), [1, 2, 3, 4, 5])
        XCTAssertEqual(s.stations.reduce(0) { $0 + $1.targets }, s.targets)
        XCTAssertEqual(s.targets, rounds.reduce(0) { $0 + $1.recorded })
        XCTAssertNotNil(s.lastAverages[5])
        XCTAssertNotNil(s.lastAverages[10])
        XCTAssertNil(s.lastAverages[20])                                   // only 14 full rounds
        XCTAssertEqual(s.schemes.map(\.scheme), [2, 7])
        XCTAssertEqual(s.schemes.reduce(0) { $0 + $1.rounds }, 15)
    }

    func testFilters() {
        let rounds = DemoMode.sampleRounds(now: now)
        let week = HomeStats.make(rounds, period: .week, type: .all, now: now)
        XCTAssertLessThan(week.rounds, 15)
        XCTAssertGreaterThan(week.rounds, 0)
        let comp = HomeStats.make(rounds, period: .all, type: .competition, now: now)
        XCTAssertEqual(comp.rounds, rounds.filter { $0.type == "Competition" }.count)
        let empty = HomeStats.make([], period: .all, type: .all, now: now)
        XCTAssertEqual(empty.rounds, 0)
        XCTAssertEqual(empty.targets, 0)
        XCTAssertNil(empty.personalBest)
        XCTAssertEqual(empty.stations.count, Round.stationCount)          // the card always shows five stations
    }
}
