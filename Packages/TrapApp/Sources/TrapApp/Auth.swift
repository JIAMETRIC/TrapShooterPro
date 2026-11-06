import CommonCrypto
import Foundation
import LocalAuthentication
import Observation
import TrapCore
import TrapPlatform

// Sign-in and accounts (CLAY NOVA Phase 1, screens 02 and 03). There is no server yet, so `DeviceAuthService` keeps
// accounts on this iPhone only: a salted PBKDF2 hash in the Keychain, never the password, never synced. A server
// implementation of `AuthService` replaces it later without touching the screens (CLAUDE.md rule 3, ADR-018).

// MARK: Account

/// What a person may do in the app. Nobody can give themselves a role above athlete: a coach role needs an invitation
/// code that an organisation approves, and the administrator role is never offered.
public enum AccountRole: String, Codable, CaseIterable, Sendable {
    case athlete, coach, administrator
    public var title: String {
        switch self { case .athlete: return "Athlete"; case .coach: return "Coach"; case .administrator: return "Administrator" }
    }
}

/// One person signed in to the app. Holds no secret; the password hash stays inside `DeviceAuthService`.
public struct Account: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var fullName: String
    /// Lower-cased and trimmed.
    public var email: String
    /// E.164 ("+919876543210"), or "".
    public var mobile: String
    /// ISO 3166 region code ("IN", "AE").
    public var country: String
    /// "yyyy-MM-dd".
    public var dateOfBirth: String
    /// The role in force. Always `.athlete` until an organisation approves more.
    public var role: AccountRole
    /// The role asked for with an invitation code, waiting for approval; nil when none was asked for.
    public var requestedRole: AccountRole?
    public var invitationCode: String
    /// False until a server has confirmed the address; on this device it stays false.
    public var emailVerified: Bool
    /// ISO timestamp.
    public var createdAt: String

    /// The first word of the name, for the greeting.
    public var firstName: String { fullName.split(separator: " ").first.map(String.init) ?? fullName }
    /// Up to two initials, for the avatar.
    public var initials: String { Self.initials(of: fullName) }
    /// Up to two initials of `name`; "?" for none.
    public static func initials(of name: String) -> String {
        let parts = name.split(separator: " ").prefix(2).compactMap(\.first)
        return parts.isEmpty ? "?" : String(parts).uppercased()
    }
    /// The country's name in the phone's language.
    public var countryName: String { Locale.current.localizedString(forRegionCode: country) ?? country }
}

// MARK: Errors

/// Everything that can go wrong signing in or creating an account, in the shooter's words (CLAUDE.md rule 11).
public enum AuthError: UserFacingError, Equatable, Sendable {
    case missing(String)
    case nameLength
    case invalidEmail
    case invalidMobile
    case invalidCountry
    case invalidBirthDate
    case tooYoung(minimum: Int)
    case passwordTooShort(minimum: Int)
    case passwordTooLong
    case passwordNeedsLetterAndDigit
    case passwordsDiffer
    case invalidInvitationCode
    case invitationNeeded
    case termsNotAccepted
    case emailTaken
    case wrongCredentials
    case locked(seconds: Int)
    case storeUnavailable
    case resetNotAuthorised

    public var message: String {
        switch self {
        case .missing(let field): return "\(field) is required."
        case .nameLength: return "Your name must be between 2 and 80 characters."
        case .invalidEmail: return "That email address does not look right."
        case .invalidMobile: return "The mobile number must start with + and the country code."
        case .invalidCountry: return "Choose your country."
        case .invalidBirthDate: return "That date of birth is not possible."
        case .tooYoung(let m): return "You must be at least \(m) to create an account."
        case .passwordTooShort(let m): return "The password must have at least \(m) characters."
        case .passwordTooLong: return "The password can have at most 128 characters."
        case .passwordNeedsLetterAndDigit: return "The password needs at least one letter and one number."
        case .passwordsDiffer: return "The two passwords are not the same."
        case .invalidInvitationCode: return "An invitation code has only letters, numbers and dashes."
        case .invitationNeeded: return "A coach account needs an invitation code from your organisation."
        case .termsNotAccepted: return "Accept the terms and the privacy policy to continue."
        case .emailTaken: return "An account with this email already exists on this iPhone."
        case .wrongCredentials: return "The email or the password is wrong."
        case .locked(let s): return "Too many attempts. Try again in \(AuthError.duration(s))."
        case .storeUnavailable: return "Your account could not be read from this iPhone."
        case .resetNotAuthorised: return "The account was not reset."
        }
    }

    public var recovery: String? {
        switch self {
        case .wrongCredentials: return "Check both and try again."
        case .emailTaken: return "Sign in instead, or reset the account from Forgot password."
        case .storeUnavailable: return "Unlock the iPhone, then try again."
        case .resetNotAuthorised: return "Confirm with Face ID, Touch ID or your passcode to reset it."
        case .tooYoung: return "Ask a parent or guardian to set up the app."
        default: return nil
        }
    }

    static func duration(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds) seconds" : "\((seconds + 59) / 60) minutes"
    }
}

// MARK: Registration and its rules

/// The Create account form.
public struct Registration: Equatable, Sendable {
    public var fullName = ""
    public var email = ""
    public var mobile = ""
    public var country = Locale.current.region?.identifier ?? ""
    public var dateOfBirth: Date?
    public var password = ""
    public var confirmPassword = ""
    public var wantsCoachRole = false
    public var invitationCode = ""
    public var acceptedTerms = false
    public init() {}
}

/// Validation at the boundary (CLAUDE.md rule 12): everything typed into Sign in and Create account passes here.
public enum AuthRules {
    public static let minimumAge = 13
    public static let minimumPasswordLength = 8
    public static let maximumPasswordLength = 128

    /// Trimmed, single-spaced, without control characters.
    public static func cleanName(_ s: String) -> String {
        let kept = s.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        return String(String.UnicodeScalarView(kept)).split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    /// Trimmed and lower-cased.
    public static func cleanEmail(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    /// "+91 98765-43210" → "+919876543210"; "" stays "".
    public static func cleanMobile(_ s: String) -> String { s.filter { $0 == "+" || $0.isASCII && $0.isNumber } }

    public static func isEmail(_ s: String) -> Bool {
        s.count <= 254 && s.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$"#, options: .regularExpression) != nil
    }
    /// E.164: a plus, then 8 to 15 digits, the first not 0.
    public static func isMobile(_ s: String) -> Bool { s.range(of: #"^\+[1-9][0-9]{7,14}$"#, options: .regularExpression) != nil }

    public static func passwordIssue(_ p: String) -> AuthError? {
        if p.isEmpty { return .missing("Password") }
        if p.count < minimumPasswordLength { return .passwordTooShort(minimum: minimumPasswordLength) }
        if p.count > maximumPasswordLength { return .passwordTooLong }
        if !p.contains(where: \.isLetter) || !p.contains(where: \.isNumber) { return .passwordNeedsLetterAndDigit }
        return nil
    }

    /// Whole years between `birth` and `now`.
    public static func age(birth: Date, now: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.year], from: birth, to: now).year ?? 0
    }

    /// Every problem with the form, in the order of the fields; empty when it can be submitted.
    public static func issues(_ r: Registration, now: Date = Date()) -> [AuthError] {
        var out: [AuthError] = []
        let name = cleanName(r.fullName)
        if name.isEmpty { out.append(.missing("Full name")) } else if !(2...80).contains(name.count) { out.append(.nameLength) }
        let email = cleanEmail(r.email)
        if email.isEmpty { out.append(.missing("Email")) } else if !isEmail(email) { out.append(.invalidEmail) }
        let mobile = cleanMobile(r.mobile)
        if !mobile.isEmpty && !isMobile(mobile) { out.append(.invalidMobile) }
        if !Locale.Region.isoRegions.contains(where: { $0.identifier == r.country }) { out.append(.invalidCountry) }
        if let dob = r.dateOfBirth {
            if dob > now || age(birth: dob, now: now) > 120 { out.append(.invalidBirthDate) }
            else if age(birth: dob, now: now) < minimumAge { out.append(.tooYoung(minimum: minimumAge)) }
        } else {
            out.append(.missing("Date of birth"))
        }
        if let p = passwordIssue(r.password) { out.append(p) }
        else if r.password != r.confirmPassword { out.append(.passwordsDiffer) }
        let code = r.invitationCode.trimmingCharacters(in: .whitespaces)
        if !code.isEmpty && code.range(of: #"^[A-Za-z0-9-]{4,32}$"#, options: .regularExpression) == nil { out.append(.invalidInvitationCode) }
        if r.wantsCoachRole && code.isEmpty { out.append(.invitationNeeded) }
        if !r.acceptedTerms { out.append(.termsNotAccepted) }
        return out
    }
}

// MARK: Service

/// Sign-in, sign-up and the account record. `DeviceAuthService` today; a server-backed one later.
public protocol AuthService: Sendable {
    func signIn(email: String, password: String, now: Date) async throws -> Account
    func register(_ form: Registration, now: Date) async throws -> Account
    func account(id: String) async throws -> Account?
    /// Removes the account's sign-in from this device. Rounds are not touched.
    func removeAccount(email: String) async throws
}

/// PBKDF2-HMAC-SHA256.
enum PasswordHasher {
    /// OWASP's 2023 figure for PBKDF2-SHA256.
    static let defaultIterations = 600_000

    static func salt(count: Int = 16) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    static func hash(_ password: String, salt: Data, iterations: Int) -> Data {
        let pw = Data(password.utf8)
        var out = [UInt8](repeating: 0, count: 32)
        let status = salt.withUnsafeBytes { s in
            pw.withUnsafeBytes { p in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), p.bindMemory(to: CChar.self).baseAddress, pw.count,
                                     s.bindMemory(to: UInt8.self).baseAddress, salt.count,
                                     CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), UInt32(iterations), &out, out.count)
            }
        }
        return status == kCCSuccess ? Data(out) : Data()
    }

    /// Compares without stopping at the first different byte.
    static func equal(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count, !a.isEmpty else { return false }
        return zip(a, b).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

/// Accounts on this iPhone only. One JSON value in the `SecretStore` (the Keychain in the app); five wrong passwords in a
/// row lock the account for 30 seconds, doubling up to 15 minutes.
public actor DeviceAuthService: AuthService {
    struct Record: Codable, Equatable {
        var account: Account
        var salt: Data
        var hash: Data
        var iterations: Int
        var failures = 0
        var lockedUntil: Date?
    }

    static let key = "accounts.v1"
    static let freeAttempts = 5
    static let firstLock: TimeInterval = 30
    static let longestLock: TimeInterval = 15 * 60

    private let store: SecretStore
    private let iterations: Int

    /// - Parameter iterations: PBKDF2 rounds; 600,000 (OWASP 2023) unless a test needs it fast.
    public init(store: SecretStore, iterations: Int = 600_000) {
        self.store = store
        self.iterations = iterations
    }

    private func load() throws -> [Record] {
        do {
            guard let data = try store.data(for: Self.key) else { return [] }
            return try JSONDecoder().decode([Record].self, from: data)
        } catch {
            TrapLog.auth.error("account store unreadable: \(String(describing: error), privacy: .public)")
            throw AuthError.storeUnavailable
        }
    }

    private func save(_ records: [Record]) throws {
        do { try store.set(try JSONEncoder().encode(records), for: Self.key) } catch {
            TrapLog.auth.error("account store unwritable: \(String(describing: error), privacy: .public)")
            throw AuthError.storeUnavailable
        }
    }

    public func signIn(email: String, password: String, now: Date) throws -> Account {
        let email = AuthRules.cleanEmail(email)
        if email.isEmpty { throw AuthError.missing("Email") }
        if password.isEmpty { throw AuthError.missing("Password") }
        var records = try load()
        guard let k = records.firstIndex(where: { $0.account.email == email }) else {
            // the same work as a real check, so a missing account takes as long as a wrong password
            _ = PasswordHasher.hash(password, salt: PasswordHasher.salt(), iterations: iterations)
            TrapLog.auth.notice("sign-in failed")
            throw AuthError.wrongCredentials
        }
        var r = records[k]
        if let until = r.lockedUntil, until > now { throw AuthError.locked(seconds: Int(until.timeIntervalSince(now).rounded(.up))) }
        if PasswordHasher.equal(PasswordHasher.hash(password, salt: r.salt, iterations: r.iterations), r.hash) {
            r.failures = 0
            r.lockedUntil = nil
            records[k] = r
            try save(records)
            TrapLog.auth.notice("signed in")
            return r.account
        }
        r.failures += 1
        if r.failures >= Self.freeAttempts {
            let wait = min(Self.longestLock, Self.firstLock * pow(2, Double(r.failures - Self.freeAttempts)))
            r.lockedUntil = now.addingTimeInterval(wait)
        }
        records[k] = r
        try save(records)
        TrapLog.auth.notice("sign-in failed, \(r.failures, privacy: .public) in a row")
        if let until = r.lockedUntil { throw AuthError.locked(seconds: Int(until.timeIntervalSince(now).rounded(.up))) }
        throw AuthError.wrongCredentials
    }

    public func register(_ form: Registration, now: Date) throws -> Account {
        if let first = AuthRules.issues(form, now: now).first { throw first }
        var records = try load()
        let email = AuthRules.cleanEmail(form.email)
        if records.contains(where: { $0.account.email == email }) { throw AuthError.emailTaken }
        let code = form.invitationCode.trimmingCharacters(in: .whitespaces)
        let account = Account(
            id: UUID().uuidString, fullName: AuthRules.cleanName(form.fullName), email: email,
            mobile: AuthRules.cleanMobile(form.mobile), country: form.country,
            dateOfBirth: form.dateOfBirth.map(DateText.day) ?? "",
            role: .athlete, requestedRole: form.wantsCoachRole ? .coach : nil, invitationCode: code,
            emailVerified: false, createdAt: DateText.iso(now))
        let salt = PasswordHasher.salt()
        records.append(Record(account: account, salt: salt,
                              hash: PasswordHasher.hash(form.password, salt: salt, iterations: iterations), iterations: iterations))
        try save(records)
        TrapLog.auth.notice("account created")
        return account
    }

    public func account(id: String) throws -> Account? { try load().first { $0.account.id == id }?.account }

    public func removeAccount(email: String) throws {
        let email = AuthRules.cleanEmail(email)
        var records = try load()
        records.removeAll { $0.account.email == email }
        try save(records)
        TrapLog.auth.notice("account removed from this device")
    }
}

// MARK: Model

/// The signed-in state for the screens. The session (the account id) lives in UserDefaults, so it ends when the app is
/// deleted, while the account itself stays in the Keychain. Sign-in is optional (App Store guideline 5.1.1: the
/// account has no server features yet), so a shooter can continue without one; that choice is remembered too.
@MainActor
@Observable
public final class AuthModel {
    /// `guest`: using the app without an account.
    public enum State: Equatable { case restoring, signedOut, guest, signedIn(Account) }

    public private(set) var state: State
    public private(set) var busy = false

    @ObservationIgnored private let service: AuthService
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    static let sessionKey = "auth.accountID"
    static let guestKey = "auth.guest"

    public var account: Account? { if case .signedIn(let a) = state { return a } else { return nil } }

    init(service: AuthService, defaults: UserDefaults = .standard, signedIn: Account? = nil, now: @escaping () -> Date = Date.init) {
        self.service = service
        self.defaults = defaults
        self.now = now
        if let a = signedIn {
            state = .signedIn(a)
        } else {
            state = Self.launchState(defaults)
        }
    }

    private static func launchState(_ defaults: UserDefaults) -> State {
        if defaults.string(forKey: sessionKey) != nil { return .restoring }
        if defaults.bool(forKey: guestKey) { return .guest }
        return .signedOut
    }

    /// Reopens the last session at launch.
    func restore() async {
        guard state == .restoring else { return }
        guard let id = defaults.string(forKey: Self.sessionKey), let a = try? await service.account(id: id) else {
            defaults.removeObject(forKey: Self.sessionKey)
            state = .signedOut
            return
        }
        state = .signedIn(a)
    }

    /// Nil when signed in; otherwise the line to show.
    func signIn(email: String, password: String) async -> DisplayError? {
        await run { try await self.service.signIn(email: email, password: password, now: self.now()) }
    }

    func register(_ form: Registration) async -> DisplayError? {
        await run { try await self.service.register(form, now: self.now()) }
    }

    /// Uses the app without an account; remembered across launches.
    func continueWithoutAccount() {
        defaults.set(true, forKey: Self.guestKey)
        state = .guest
    }

    /// Back to Sign in, from an account or from using the app without one.
    func signOut() {
        defaults.removeObject(forKey: Self.sessionKey)
        defaults.removeObject(forKey: Self.guestKey)
        state = .signedOut
        TrapLog.auth.notice("signed out")
    }

    /// Settings → Delete account (App Store guideline 5.1.1(v)): removes the signed-in account from this iPhone and
    /// signs out. Rounds, settings and recordings stay.
    func deleteAccount() async -> DisplayError? {
        guard let a = account else { return nil }
        do {
            try await service.removeAccount(email: a.email)
        } catch {
            return DisplayError(any: error)
        }
        signOut()
        return nil
    }

    /// Forgot password, while there is no server to send a reset link: after Face ID, Touch ID or the passcode, the
    /// sign-in for `email` is removed from this iPhone so a new account can be made. Rounds stay.
    func resetOnDevice(email: String) async -> DisplayError? {
        guard await DeviceOwner.confirm(reason: "Reset the TrapShoot sign-in on this iPhone") else {
            return DisplayError(any: AuthError.resetNotAuthorised)
        }
        do {
            try await service.removeAccount(email: email)
            return nil
        } catch {
            return DisplayError(any: error)
        }
    }

    private func run(_ body: @escaping () async throws -> Account) async -> DisplayError? {
        busy = true
        defer { busy = false }
        do {
            let a = try await body()
            defaults.set(a.id, forKey: Self.sessionKey)
            defaults.removeObject(forKey: Self.guestKey)
            state = .signedIn(a)
            return nil
        } catch {
            return DisplayError(any: error, fallback: "Something went wrong. Try again.")
        }
    }
}

/// Face ID, Touch ID or the device passcode. A phone without a passcode has nothing to confirm with, so it passes.
enum DeviceOwner {
    @MainActor
    static func confirm(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return (error as? LAError)?.code == .passcodeNotSet
        }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }
}
