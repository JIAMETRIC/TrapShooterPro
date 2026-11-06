import SwiftUI
import TrapCore
import TrapDesign

// Splash, Sign in, Create account and Forgot password (CLAY NOVA Phase 1, screens 01–03), drawn with TrapDesign.

/// Shows the app once someone is signed in; the splash while the last session reopens; Sign in otherwise.
@MainActor
struct AuthGate<Content: View>: View {
    @Environment(AppModel.self) private var app
    @ViewBuilder var content: Content

    var body: some View {
        Group {
            switch app.auth.state {
            case .restoring: SplashView().task { await app.auth.restore() }
            case .signedOut: NavigationStack { SignInScreen() }
            case .signedIn, .guest: content
            }
        }
        .animation(BWMotion.standard, value: app.auth.state)
        .onChange(of: app.auth.account, initial: true) { _, a in
            // demo mode writes nothing to the real settings
            guard let a, !DemoMode.isOn else { return }
            // the shooter's name ends every session id; take it from the account when Settings has none
            app.update { s in
                if s.profile.name.isEmpty { s.profile.name = a.fullName }
                if s.profile.dateOfBirth.isEmpty { s.profile.dateOfBirth = a.dateOfBirth }
            }
        }
    }
}

/// Screen 01: the mark, the name and a spinner while the session reopens. No controls.
@MainActor
struct SplashView: View {
    var body: some View {
        VStack(spacing: BWMetrics.s4) {
            BrandMark(size: 88)
            Text(AppConstants.displayName).bwDisplay(.largeTitle).foregroundStyle(BW.text)
            ProgressView().tint(BW.tint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BW.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(AppConstants.displayName), loading")
    }
}

/// The app mark: a target reticle on the deep-blue tile.
@MainActor
struct BrandMark: View {
    var size: CGFloat = 64
    var body: some View {
        Image(systemName: "scope")
            .font(.system(size: size * 0.5, weight: .medium))
            .foregroundStyle(BW.onAccent)
            .frame(width: size, height: size)
            .background(BW.accentFill, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .bwShadow(.card)
            .accessibilityHidden(true)
    }
}

/// The page every auth screen sits on: centred column on iPad, gutter on iPhone.
@MainActor
private struct AuthPage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BWMetrics.s4) { content }
                .padding(BWMetrics.gutter)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(BW.surface)
    }
}

// MARK: Sign in

/// Screen 02.
@MainActor
struct SignInScreen: View {
    @Environment(AppModel.self) private var app
    @State private var email = ""
    @State private var password = ""
    @State private var error: DisplayError?
    @State private var legal: LegalDocument?
    @State private var forgot = false
    @FocusState private var focus: Field?
    private enum Field { case email, password }

    var body: some View {
        AuthPage {
            VStack(alignment: .leading, spacing: BWMetrics.s2) {
                BrandMark()
                Text(AppConstants.displayName).bwDisplay(.largeTitle).foregroundStyle(BW.text).padding(.top, BWMetrics.s2)
                Text("Olympic Trap timing, scoring and analysis.")
                    .font(BWFont.secondary).foregroundStyle(BW.textSecondary)
            }
            .padding(.top, BWMetrics.s8)
            .padding(.bottom, BWMetrics.s2)

            VStack(alignment: .leading, spacing: BWMetrics.s3) {
                BWSectionLabel("Sign in")
                LabeledField("Email") {
                    TextField("name@example.com", text: $email)
                        .textContentType(.username).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .focused($focus, equals: .email).submitLabel(.next)
                        .onSubmit { focus = .password }
                        .accessibilityIdentifier("signin.email")
                }
                LabeledField("Password") {
                    PasswordField(placeholder: "Password", text: $password, content: .password)
                        .focused($focus, equals: .password).submitLabel(.go)
                        .onSubmit(submit)
                        .accessibilityIdentifier("signin.password")
                }
                MessageLine(error: error)
                Button(action: submit) { BusyLabel(title: "Sign in", busy: app.auth.busy) }
                .buttonStyle(.bwPrimary)
                .disabled(app.auth.busy)
                .accessibilityIdentifier("signin.submit")
                Button("Forgot password?") { forgot = true }
                    .font(BWFont.secondary.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: BWMetrics.actionHeight)
            }
            .bwCard()

            VStack(spacing: BWMetrics.s3) {
                Text("New to \(AppConstants.displayName)?").font(BWFont.secondary).foregroundStyle(BW.textSecondary)
                NavigationLink {
                    CreateAccountScreen()
                } label: {
                    Text("Create account").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bwSecondary)
                .accessibilityIdentifier("signin.create")
                Button("Continue without an account") { app.auth.continueWithoutAccount() }
                    .font(BWFont.secondary.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: BWMetrics.actionHeight)
                    .accessibilityIdentifier("signin.guest")
            }
            .frame(maxWidth: .infinity)

            LocalOnlyNote()
            LegalLinks(legal: $legal)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $legal) { LegalSheet(document: $0) }
        .sheet(isPresented: $forgot) { ForgotPasswordSheet(email: email) }
    }

    private func submit() {
        focus = nil
        Task { error = await app.auth.signIn(email: email, password: password) }
    }
}

/// A full-width primary button label with a spinner while the request runs.
@MainActor
private struct BusyLabel: View {
    let title: String
    let busy: Bool
    var body: some View {
        HStack(spacing: BWMetrics.s2) {
            if busy { ProgressView().tint(BW.onAccent) }
            Text(title)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A secure field with a show / hide eye; 44 pt tap target on the eye.
@MainActor
struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    var content: UITextContentType = .password
    @State private var shown = false

    var body: some View {
        HStack(spacing: BWMetrics.s2) {
            Group {
                if shown { TextField(placeholder, text: $text) } else { SecureField(placeholder, text: $text) }
            }
            .textContentType(content)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            Button { shown.toggle() } label: {
                Image(systemName: shown ? "eye.slash" : "eye").foregroundStyle(BW.textMuted)
                    .frame(width: BWMetrics.iconButton, height: BWMetrics.iconButton)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(shown ? "Hide password" : "Show password")
        }
    }
}

/// Says where the account lives while there is no server.
@MainActor
private struct LocalOnlyNote: View {
    var body: some View {
        Label {
            Text("Your account stays on this iPhone. Nothing is sent to a server.")
        } icon: {
            Image(systemName: "lock.iphone")
        }
        .font(BWFont.note).foregroundStyle(BW.textMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
private struct LegalLinks: View {
    @Binding var legal: LegalDocument?
    var body: some View {
        HStack(spacing: BWMetrics.s4) {
            Button("Privacy policy") { legal = .privacy }
            Button("Terms of service") { legal = .terms }
        }
        .font(BWFont.note.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: BWMetrics.actionHeight)
    }
}

// MARK: Create account

/// Screen 03.
@MainActor
struct CreateAccountScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var form = Registration()
    @State private var error: DisplayError?
    @State private var legal: LegalDocument?

    var body: some View {
        AuthPage {
            VStack(alignment: .leading, spacing: BWMetrics.s1) {
                Text("Create account").bwDisplay(.title).foregroundStyle(BW.text)
                Text("Fields marked * are required.").font(BWFont.secondary).foregroundStyle(BW.textSecondary)
            }

            VStack(alignment: .leading, spacing: BWMetrics.s3) {
                BWSectionLabel("Your details")
                LabeledField("Full name *") {
                    TextField("First and last name", text: $form.fullName)
                        .textContentType(.name).textInputAutocapitalization(.words)
                        .accessibilityIdentifier("register.name")
                }
                LabeledField("Email *") {
                    TextField("name@example.com", text: $form.email)
                        .textContentType(.emailAddress).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("register.email")
                }
                LabeledField("Mobile number") {
                    TextField("+91 98765 43210", text: $form.mobile)
                        .textContentType(.telephoneNumber).keyboardType(.phonePad)
                }
                Text("With the country code. SMS verification comes with the \(AppConstants.displayName) server.")
                    .font(BWFont.note).foregroundStyle(BW.textMuted)
                LabeledField("Country *") {
                    Picker("Country", selection: $form.country) {
                        if form.country.isEmpty { Text("Choose").tag("") }
                        ForEach(Countries.all, id: \.code) { Text($0.name).tag($0.code) }
                    }
                    .pickerStyle(.menu)
                }
                LabeledField("Date of birth *") {
                    if let dob = form.dateOfBirth {
                        DatePicker("Date of birth", selection: Binding(get: { dob }, set: { form.dateOfBirth = $0 }),
                                   in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                    } else {
                        Button("Add date of birth") {
                            form.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())
                        }
                        .font(BWFont.body)
                    }
                }
                Text("Used for age categories and safeguarding. You must be \(AuthRules.minimumAge) or older.")
                    .font(BWFont.note).foregroundStyle(BW.textMuted)
            }
            .bwCard()

            VStack(alignment: .leading, spacing: BWMetrics.s3) {
                BWSectionLabel("Password")
                LabeledField("Password *") {
                    PasswordField(placeholder: "At least \(AuthRules.minimumPasswordLength) characters", text: $form.password, content: .newPassword)
                        .accessibilityIdentifier("register.password")
                }
                LabeledField("Confirm password *") {
                    PasswordField(placeholder: "Type it again", text: $form.confirmPassword, content: .newPassword)
                        .accessibilityIdentifier("register.confirm")
                }
                Text("At least \(AuthRules.minimumPasswordLength) characters, with a letter and a number.")
                    .font(BWFont.note).foregroundStyle(BW.textMuted)
            }
            .bwCard()

            VStack(alignment: .leading, spacing: BWMetrics.s3) {
                BWSectionLabel("Role")
                Picker("Role", selection: $form.wantsCoachRole) {
                    Text("Athlete").tag(false)
                    Text("Coach").tag(true)
                }
                .pickerStyle(.segmented)
                LabeledField(form.wantsCoachRole ? "Invitation code *" : "Invitation code") {
                    TextField("From your club or organisation", text: $form.invitationCode)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                }
                Text(form.wantsCoachRole
                     ? "Coach access starts once your organisation approves the code. Until then the account works as an athlete account."
                     : "Optional. Links you to a club or coach once approved.")
                    .font(BWFont.note).foregroundStyle(BW.textMuted)
            }
            .bwCard()

            VStack(alignment: .leading, spacing: BWMetrics.s3) {
                Toggle(isOn: $form.acceptedTerms) {
                    Text("I accept the Terms of service and the Privacy policy. *").font(BWFont.secondary)
                }
                .tint(BW.accentFill)
                .accessibilityIdentifier("register.terms")
                LegalLinks(legal: $legal)
            }
            .bwCard()

            MessageLine(error: error)
            Button(action: submit) { BusyLabel(title: "Create account", busy: app.auth.busy) }
            .buttonStyle(.bwPrimary)
            .disabled(app.auth.busy)
            .accessibilityIdentifier("register.submit")
            Button("Back to sign in") { dismiss() }
                .font(BWFont.secondary.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: BWMetrics.actionHeight)
            LocalOnlyNote()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $legal) { LegalSheet(document: $0) }
    }

    private func submit() {
        if let first = AuthRules.issues(form).first {
            error = DisplayError(any: first)
            return
        }
        Task { error = await app.auth.register(form) }
    }
}

/// Countries for the picker: two-letter ISO regions, by name in the phone's language.
enum Countries {
    struct Entry { let code: String, name: String }
    static let all: [Entry] = Locale.Region.isoRegions
        .map(\.identifier)
        .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
        .compactMap { code in Locale.current.localizedString(forRegionCode: code).map { Entry(code: code, name: $0) } }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

// MARK: Forgot password

/// With no server there is no reset email. The sign-in can be removed from this iPhone after Face ID, Touch ID or the
/// passcode, so a new account can be made; rounds stay.
@MainActor
private struct ForgotPasswordSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State var email: String
    @State private var error: DisplayError?
    @State private var done = false

    var body: some View {
        NavigationStack {
            AuthPage {
                Text("Reset your sign-in").bwDisplay(.title2).foregroundStyle(BW.text)
                Text("\(AppConstants.displayName) has no server yet, so there is no reset email. You can remove the sign-in for this email from this iPhone and create the account again. Your rounds, settings and recordings stay.")
                    .font(BWFont.secondary).foregroundStyle(BW.textSecondary)
                LabeledField("Email") {
                    TextField("name@example.com", text: $email)
                        .textContentType(.username).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                if done {
                    Text("The sign-in was removed. Create the account again to continue.")
                        .font(BWFont.secondary).foregroundStyle(BW.success.foreground)
                        .padding(BWMetrics.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BW.success.background, in: RoundedRectangle(cornerRadius: BWMetrics.radiusMD))
                }
                MessageLine(error: error)
                if done {
                    Button("Done") { dismiss() }.buttonStyle(.bwPrimary)
                } else {
                    Button("Reset on this iPhone") {
                        Task {
                            error = await app.auth.resetOnDevice(email: email)
                            done = error == nil
                        }
                    }
                    .buttonStyle(.bwDestructive)
                    .disabled(AuthRules.cleanEmail(email).isEmpty)
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: Legal

enum LegalDocument: String, Identifiable {
    case privacy, terms
    var id: String { rawValue }
    var title: String { self == .privacy ? "Privacy policy" : "Terms of service" }
    var paragraphs: [String] {
        switch self {
        case .privacy:
            return [
                "\(AppConstants.displayName) keeps everything on your iPhone or iPad. There is no server, no analytics and no advertising.",
                "Account: your name, email, mobile number, country, date of birth and role are stored on this device. Your password is never stored; only a salted hash is kept in the device Keychain, which is not synced or backed up to other devices.",
                "Rounds, settings and round audio stay on the device and leave it only when you share or export a file yourself.",
                "Microphone: used only while the shot timer runs. Location: used only for the optional weather fill; the rounded position is sent once to Open-Meteo and not stored.",
                "Questions: jiametric@gmail.com"
            ]
        case .terms:
            return [
                "\(AppConstants.displayName) is a training tool for Olympic Trap. Scores and times recorded in the app are not official results.",
                "You are responsible for the safe handling of firearms and for following the rules of your range and federation.",
                "Your data stays on your device. You can export or delete it at any time.",
                "Questions: jiametric@gmail.com"
            ]
        }
    }
}

@MainActor
private struct LegalSheet: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            AuthPage {
                ForEach(document.paragraphs, id: \.self) { p in
                    Text(p).font(BWFont.body).foregroundStyle(BW.text)
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
